lib: customLib:
{
	settings = {
		general = {
			showTheseItemsOnTheDesktop = lib.mkOption {
				description = "Finder > Settings > General > Show these items on the desktop";
				type = lib.types.nullOr (lib.types.submodule {
					hardDisks = lib.mkOption {
						description = "Hard disks";
						type = lib.types.bool;
						default = true;
					};
					externalDisks = lib.mkOption {
						description = "External disks";
						type = lib.types.bool;
						default = true;
					};
					cdsDvdsAndiPods = lib.mkOption {
						description = "CDs, DVDs, and iPods";
						type = lib.types.bool;
						default = false;
					};
					connectedServers = lib.mkOption {
						description = "Connected servers";
						type = lib.types.bool;
						default = false;
					};
				});
				default = {};
			};
			# newFinderWindowsShow
			# syncDesktopAndDocumentsFolders
			openFoldersInNewTabsInsteadOfNewWindows = lib.mkOption {
				description = "Finder > Settings > General > Open folders in tabs instead of new windows";
				type = lib.types.nullOr lib.types.bool;
				default = null;
			};
		};
		sidebar = {
			recentTags = lib.mkOption {
				description = "Finder > Sidebar > Show Recent Tags";
				type = lib.types.nullOr lib.types.bool;
				default = null;
			};
		};

		advanced = {
			showAllFileExtensions = lib.mkOption {
				description = "Finder > Advanced > Show all filename extensions";
				type = lib.types.nullOr lib.types.bool;
				default = null;
			};

			showWarningBeforeChangingAnExtension = lib.mkOption {
				description = "Finder > Advanced > Show warning before changing an extension";
				type = lib.types.nullOr lib.types.bool;
				default = null;
			};

			showWarningBeforeRemovingFromiCloudDrive = lib.mkOption {
				description = "Finder > Advanced > Show warning before removing from iCloud Drive";
				type = lib.types.nullOr lib.types.bool;
				default = null;
			};

			showWarningBeforeEmptyingTheTrash = lib.mkOption {
				description = "Finder > Advanced > Show warning before emptying the Trash";
				type = lib.types.nullOr lib.types.bool;
				default = null;
			};

			removeItemsFromTheTrashAfter30Days = lib.mkOption {
				description = "Finder > Advanced > Remove items from the Trash after 30 days";
				type = lib.types.nullOr lib.types.bool;
				default = null;
			};

			keepFoldersOnTop = lib.mkOption {
				description = "Finder > Advanced > Keep folders on top when sorting by name";
				type = lib.types.nullOr (lib.types.submodule {
					inWindowsWhenShortingByName = lib.mkOption {
						description = "In windows when sorting by name";
						type = lib.types.bool;
						default = true;
					};
					onDesktop = lib.mkOption {
						description = "On Desktop";
						type = lib.types.bool;
						default = true;
					};
				});
				default = {};
			};

			whenPerformingASearch =
				let
					mapping = {
						"Search This Mac" = "SCev";
						"Search the Current Folder" = "SCcf";
						"Use the Previous Search Scope" = "SCsp";
					};
				in
				lib.mkOption {
					description = "Finder > Advanced > When performing a search";
					type = lib.types.nullOr (lib.types.enum lib.attrNames mapping);
					apply = value: if builtins.isNull value then null else mapping.${value};
					default = null;
				};

		};
	};
	menuBar = {
		view = {
			showTabBar = lib.mkOption {
				description = "Finder > View > Show Tab Bar";
				type = lib.types.nullOr lib.types.bool;
				default = null;
			};

			showSidebar = lib.mkOption {
				description = "Finder > View > Show Sidebar";
				type = lib.types.nullOr lib.types.bool;
				default = null;
			};
			showPreview = lib.mkOption {
				description = "Finder > View > Show Preview";
				type = lib.types.nullOr lib.types.bool;
				default = null;
			};

			showPathBar = lib.mkOption {
				description = "Finder > View > Show Path Bar";
				type = lib.types.nullOr lib.types.bool;
				default = null;
			};
			showStatusBar = lib.mkOption {
				description = "Finder > View > Show Status Bar";
				type = lib.types.nullOr lib.types.bool;
				default = null;
			};
			
		};
	};
}
