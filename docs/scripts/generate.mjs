// Generates the settings reference from the flake's `documentation` output: every option
// (options.json, from optionIndex) and coverage.json (what's verified, and what isn't covered).
//
//   DOCS_DATA=$(nix build --no-link --print-out-paths ..#documentation) node scripts/generate.mjs
//
// Writes one page per System Settings pane (and per app) to src/content/docs/settings/, and the
// sidebar for them to src/generated/sidebar.json. Big panes (Accessibility, Keyboard) get a page
// per section.
import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const data = process.env.DOCS_DATA ?? ".data";
if (!existsSync(join(data, "options.json"))) {
	console.error(`no documentation data in ${data}; run: nix build ..#documentation -o docs/.data`);
	process.exit(1);
}

const options = JSON.parse(readFileSync(join(data, "options.json"), "utf8"));
const outDir = "src/content/docs/settings";
const generatedDir = "src/generated";

// System Settings' sidebar order, then the apps
const paneOrder = [
	"Wi‑Fi", "Network", "Battery", "General", "Accessibility", "Appearance", "Apple Intelligence & Siri",
	"Desktop & Dock", "Displays", "Menu Bar", "Spotlight", "Wallpaper", "Notifications", "Sound", "Focus",
	"Lock Screen", "Privacy & Security", "Keyboard", "Trackpad", "Printers & Scanners",
];
const apps = ["Finder", "Journal", "Voice Memos"];

// panes with this many options get a page per section
const splitAt = 60;

const slug = (text) => text.toLowerCase().replace(/&/g, "and").replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");

// --- coverage.json: which options are verified, and what each pane doesn't cover --------------

const coverage = JSON.parse(readFileSync(join(data, "coverage.json"), "utf8"));
const verified = new Set(Object.values(coverage.verified).flat());
const notCovered = {}; // page title -> [{ title, reason }]
for (const [pane, reasons] of Object.entries(coverage.notCovered))
	for (const [reason, titles] of Object.entries(reasons))
		for (const title of titles) (notCovered[pane] ??= []).push({ title, reason });

// --- options grouped into pages --------------------------------------------------------------

// the page an option belongs to: its pane in System Settings, or its app
function pageOf(option) {
	const [root, pane] = option.path;
	if (option.option.startsWith("applications.systemSettings.")) {
		// a few settings are found outside System Settings (the Dock's contents, the menu bar's
		// layout, App Store updates); they're documented with the pane their option is under
		if (root === "System Settings") return pane;
		const segment = option.option.split(".")[2];
		const match = options.find((o) => o.option.split(".")[2] === segment && o.path[0] === "System Settings");
		return match ? match.path[1] : root;
	}
	return root;
}

const pages = {};
for (const option of options) (pages[pageOf(option)] ??= []).push(option);

// --- how an option reads in the docs ---------------------------------------------------------

const clean = (text) => (text ?? "").replace(/\s+/g, " ").trim();

// what values an option takes, in plain words
function valuesOf(option) {
	const { kind, choices, range } = option;
	switch (kind) {
		case "bool": return { text: "`true` or `false`" };
		case "enum": return { text: "One of:", choices };
		case "number":
			return { text: `A number from ${range.min} to ${range.max}${range.unit ? ` (${range.unit})` : ""}` };
		case "string": return { text: "Text" };
		case "list": return { text: "A list of strings" };
		case "snapshot": return { text: "A directory captured with `nix run …#capture` — see [Snapshots](/nix-plist-manager/guides/snapshots/)" };
		case "switches": return { text: "An attribute set of switches, each `true`, `false` or left out:", choices };
		case "flags": return { text: "An attribute set of flags, each `true`, `false` or left out:", choices };
		case "color": return { text: "`\"Default\"`, or a color as `{ red; green; blue; alpha; }`, each from 0 to 1" };
		case "modifiers": return { text: "The modifier keys to hold, each `true` or `false`:", choices };
		case "apps": return { text: "A size per app, by bundle identifier, one of:", choices };
		case "applications": return { text: "Per app, by bundle identifier (see the example)" };
		case "sharedFolders": return { text: "Folders to share: path → name" };
		case "services": return { text: "Per service id: `false`, `true`, or keys like `\"⌘⇧S\"`" };
		case "shortcut": return { text: "`false` (off), `true` (on, default keys), or keys like `\"⌘⇧S\"` — see [Keyboard shortcuts](/nix-plist-manager/guides/keyboard-shortcuts/)" };
		default: return { text: `\`${clean(option.type).replace(/^null or /, "").replace(/ or value "unset" \(singular enum\)$/, "")}\`` };
	}
}

// the processes an option restarts, from the script it renders to
function restartsOf(option) {
	const names = new Set();
	for (const script of Object.values(option.commands ?? {}))
		for (const match of script.matchAll(/killall(?: -KILL)? '?([^' \n|]+)'?/g)) names.add(match[1]);
	return [...names];
}

const needsLogout = (option) => /after logging out|log out/i.test(option.description ?? "");

function optionProps(option) {
	const values = valuesOf(option);
	return {
		title: option.path.at(-1),
		path: option.option,
		ui: option.path,
		module: option.module,
		example: option.example,
		values: values.text,
		choices: values.choices ?? [],
		description: clean(option.description),
		verified: verified.has(option.option),
		canUnset: option.canUnset,
		logout: needsLogout(option),
		restarts: restartsOf(option),
		storage: option.storage.filter((key) => key.key).map((key) => ({
			domain: key.domain, key: key.key, byHost: key.byHost, system: key.scope === "system",
		})),
		commands: option.commands ?? {},
	};
}

// JSX props from plain data; MDX evaluates them as JavaScript
const props = (object) => Object.entries(object).map(([key, value]) => `${key}={${JSON.stringify(value)}}`).join(" ");

// --- writing pages ---------------------------------------------------------------------------

// sections of a page: the part of the UI path after the pane (or app); options directly in the
// pane come first
function sections(pageOptions, depth) {
	const groups = new Map();
	for (const option of pageOptions) {
		const rest = option.path.slice(depth, -1);
		const name = rest[0] ?? "";
		if (!groups.has(name)) groups.set(name, []);
		groups.get(name).push(option);
	}
	return [...groups.entries()].sort(([a], [b]) => (a === "" ? -1 : b === "" ? 1 : 0));
}

// an option's heading: its path inside the section, so "Magnification › Size" isn't just "Size"
const headingOf = (option, depth, inSection) => option.path.slice(depth + (inSection ? 1 : 0)).join(" › ") || option.path.at(-1);

function optionsMarkdown(pageOptions, depth) {
	return sections(pageOptions, depth).map(([name, group]) => {
		const heading = name ? `## ${name}\n\n` : "";
		return heading + group.map((option) => `### ${headingOf(option, depth, name !== "")}\n\n<Option ${props(optionProps(option))} />\n`).join("\n");
	}).join("\n");
}

function notCoveredMarkdown(title) {
	const items = notCovered[title] ?? [];
	if (!items.length) return "";
	const list = items.map(({ title, reason }) => `- **${title}** — ${reason}`).join("\n");
	return `\n## Not covered\n\nWhat this pane shows that can't be declared, and why:\n\n<details>\n<summary>${items.length} settings</summary>\n\n${list}\n\n</details>\n`;
}

function write(file, frontmatter, body) {
	const yaml = Object.entries(frontmatter).map(([key, value]) => `${key}: ${JSON.stringify(value)}`).join("\n");
	writeFileSync(file, `---\n${yaml}\n---\n\nimport Option from "@components/Option.astro";\nimport PaneSummary from "@components/PaneSummary.astro";\n\n${body}`);
}

function summary(pageOptions, where) {
	const count = pageOptions.length;
	const verifiedCount = pageOptions.filter((o) => verified.has(o.option)).length;
	const modules = [...new Set(pageOptions.map((o) => o.module))];
	return `<PaneSummary ${props({ count, verified: verifiedCount, where, modules })} />\n\n`;
}

rmSync(outDir, { recursive: true, force: true });
mkdirSync(outDir, { recursive: true });
mkdirSync(generatedDir, { recursive: true });

const sidebarPanes = [];
const sidebarApps = [];
const ordered = [...paneOrder, ...Object.keys(pages).filter((title) => !paneOrder.includes(title) && !apps.includes(title)).sort()];

for (const title of [...ordered, ...apps]) {
	const pageOptions = pages[title];
	if (!pageOptions) continue;
	const isApp = apps.includes(title);
	const where = isApp ? title : `System Settings › ${title}`;
	const depth = isApp ? 1 : 2;
	const target = isApp ? sidebarApps : sidebarPanes;

	if (pageOptions.length < splitAt) {
		write(join(outDir, `${slug(title)}.mdx`), { title, description: `Declare ${where} in Nix.` },
			summary(pageOptions, where) + optionsMarkdown(pageOptions, depth) + notCoveredMarkdown(title));
		target.push({ label: title, link: `/settings/${slug(title)}/` });
		continue;
	}

	// a page per section, in a sidebar group of its own
	mkdirSync(join(outDir, slug(title)), { recursive: true });
	const items = [];
	const sectionList = sections(pageOptions, depth);
	write(join(outDir, slug(title), "index.mdx"), { title, description: `Declare ${where} in Nix.`, sidebar: { label: "Overview", order: 0 } },
		summary(pageOptions, where)
		+ sectionList.map(([name, group]) => `- [${name || "General"}](./${slug(name || "general")}/) — ${group.length} option${group.length === 1 ? "" : "s"}`).join("\n")
		+ "\n" + notCoveredMarkdown(title));
	items.push({ label: "Overview", link: `/settings/${slug(title)}/` });
	for (const [name, group] of sectionList) {
		const sectionTitle = name || "General";
		write(join(outDir, slug(title), `${slug(name || "general")}.mdx`), { title: sectionTitle, description: `Declare ${where} › ${sectionTitle} in Nix.` },
			summary(group, `${where} › ${sectionTitle}`) + optionsMarkdown(group, depth + 1));
		items.push({ label: sectionTitle, link: `/settings/${slug(title)}/${slug(name || "general")}/` });
	}
	target.push({ label: title, collapsed: true, items });
}

const count = (predicate) => options.filter(predicate).length;
const totals = {
	options: options.length,
	verified: count((o) => verified.has(o.option)),
	user: count((o) => o.module === "home-manager"),
	system: count((o) => o.module === "darwin"),
	systemSettings: count((o) => o.option.startsWith("applications.systemSettings.")),
	finder: count((o) => o.option.startsWith("applications.finder.")),
	otherApps: count((o) => !o.option.startsWith("applications.systemSettings.") && !o.option.startsWith("applications.finder.")),
	apps: apps.filter((app) => pages[app]).length,
	panes: Object.keys(pages).filter((title) => !apps.includes(title)).length,
};
writeFileSync(join(generatedDir, "sidebar.json"), JSON.stringify({ panes: sidebarPanes, apps: sidebarApps }, null, "\t"));
writeFileSync(join(generatedDir, "stats.json"), JSON.stringify(totals, null, "\t"));
console.log(`generated ${Object.keys(pages).length} pages for ${totals.options} options (${totals.verified} verified)`);
