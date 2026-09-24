// @ts-check
import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";
import { readFileSync } from "node:fs";

const generated = JSON.parse(readFileSync(new URL("./src/generated/sidebar.json", import.meta.url), "utf8"));

export default defineConfig({
	site: "https://sushydev.github.io",
	base: "/nix-plist-manager/",
	integrations: [
		starlight({
			title: "nix-plist-manager",
			description: "Your Mac's System Settings, declared in Nix.",
			social: [{ icon: "github", label: "GitHub", href: "https://github.com/sushydev/nix-plist-manager" }],
			customCss: ["./src/styles/theme.css"],
			lastUpdated: false,
			pagination: false,
			sidebar: [
				{
					label: "Start here",
					items: [
						{ label: "Introduction", link: "/" },
						{ label: "Install", link: "/guides/install/" },
						{ label: "Start from your Mac", link: "/guides/from-your-mac/" },
					],
				},
				{
					label: "Guides",
					items: [
						{ label: "How settings are applied", link: "/guides/how-it-works/" },
						{ label: "Keyboard shortcuts", link: "/guides/keyboard-shortcuts/" },
						{ label: "Snapshots", link: "/guides/snapshots/" },
					],
				},
				{ label: "System Settings", items: generated.panes },
				{ label: "Apps", items: generated.apps },
			],
		}),
	],
});
