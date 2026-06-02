{ lib, commandsLib, ... }:
{
	appleIntelligence = rec {
		path = [ "System Settings" "Apple Intelligence & Siri" "Apple Intelligence" ];
		description = "Enable or disable Apple Intelligence.";

		mapping = {
			"unset" = {
				command = commandsLib.defaults.delete "com.apple.CloudSubscriptionFeatures.optIn" "10334750688";
			};
			"true" = {
				command = "/usr/bin/defaults write com.apple.CloudSubscriptionFeatures.optIn 10334750688 -bool true 2>/dev/null || true";
			};
			"false" = {
				command = "/usr/bin/defaults write com.apple.CloudSubscriptionFeatures.optIn 10334750688 -bool false 2>/dev/null || true";
			};
		};

		default = null;

		option = lib.mkOption {
			inherit description default;
			type = lib.types.nullOr (lib.types.either lib.types.bool (lib.types.enum [ "unset" ]));
		};

		config = {
			perUser = true;
			command = value:
				if builtins.isNull value then mapping."unset".command
				else if value == "unset" then mapping."unset".command
				else if value == true then mapping."true".command
				else mapping."false".command;
		};
	};

	siri = {
		enable = rec {
			path = [ "System Settings" "Apple Intelligence & Siri" "Siri Requests" "Siri" ];
			description = "Enable or disable Siri.";

			mapping = {
				"unset" = {
					command = commandsLib.defaults.delete "com.apple.assistant.support" "Assistant Enabled";
				};
				"true" = {
					command = "/usr/bin/defaults write com.apple.assistant.support 'Assistant Enabled' -bool true 2>/dev/null || true";
				};
				"false" = {
					command = "/usr/bin/defaults write com.apple.assistant.support 'Assistant Enabled' -bool false 2>/dev/null || true";
				};
			};

			default = null;

			option = lib.mkOption {
				inherit description default;
				type = lib.types.nullOr (lib.types.either lib.types.bool (lib.types.enum [ "unset" ]));
			};

			config = {
				perUser = true;
				command = value:
					if builtins.isNull value then mapping."unset".command
					else if value == "unset" then mapping."unset".command
					else if value == true then mapping."true".command
					else mapping."false".command;
			};
		};
	};

	siriResponses = rec {
		path = [ "System Settings" "Apple Intelligence & Siri" "Siri Requests" "Siri Responses" ];
		description = "Configure Siri response preference: 'automatic' (1), 'prefer-spoken' (2), or 'prefer-silent' (3).";

		mapping = {
			"unset" = {
				command = commandsLib.defaults.delete "com.apple.assistant.backedup" "Use device speaker for TTS";
			};
			"automatic" = {
				command = "/usr/bin/defaults write com.apple.assistant.backedup 'Use device speaker for TTS' -int 1 2>/dev/null || true";
			};
			"prefer-spoken" = {
				command = "/usr/bin/defaults write com.apple.assistant.backedup 'Use device speaker for TTS' -int 2 2>/dev/null || true";
			};
			"prefer-silent" = {
				command = "/usr/bin/defaults write com.apple.assistant.backedup 'Use device speaker for TTS' -int 3 2>/dev/null || true";
			};
		};

		default = null;

		option = lib.mkOption {
			inherit description default;
			type = lib.types.nullOr (lib.types.either (lib.types.enum [ "automatic" "prefer-spoken" "prefer-silent" ]) (lib.types.enum [ "unset" ]));
		};

		config = {
			perUser = true;
			command = value:
				if builtins.isNull value then mapping."unset".command
				else if value == "unset" then mapping."unset".command
				else mapping."${value}".command;
		};
	};
}
