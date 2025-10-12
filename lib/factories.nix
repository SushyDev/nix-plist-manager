{ lib }:
let
  types = import ./types.nix { inherit lib; };
  commands = import ./commands.nix { inherit lib; };
  
  # Base option factory that handles common structure
  mkPlistOption = { key, description, commands, default ? null, perUser ? true }: config: {
    inherit description default;
    
    option = lib.mkOption (config.option // { 
      inherit description default; 
    });
    
    config = {
      inherit perUser;
      command = config.command commands;
    };
  };

  # Command generators using guard clauses
  commandGenerators = {
    boolCommand = commands: value:
      if builtins.isNull value then null
      else if value == "unset" then commands.delete
      else commands.writeBool value;
      
    enumToBoolCommand = commands: valueMap: value:
      if builtins.isNull value then null
      else if value == "unset" then commands.delete  
      else commands.writeBool valueMap.${toString value};
      
    enumToIntCommand = commands: valueMap: value:
      if builtins.isNull value then null
      else if value == "unset" then commands.delete
      else commands.writeInt valueMap.${value};
      
    bitmaskCommand = commands: value:
      if builtins.isNull value then null
      else if value == "unset" then commands.delete
      else commands.writeInt value;
  };

  # Bitmask calculation utility
  calculateBitmask = mapping: options:
    lib.foldl' builtins.bitOr 0 (lib.mapAttrsToList (name: bitValue:
      if builtins.isNull (options.${name} or null) then 0
      else if options.${name} then bitValue
      else 0
    ) mapping);

in
{
	mkBoolOption = { key, description, commands, default ? null, perUser ? true }:
		mkPlistOption { inherit key description commands default perUser; } {
			option.type = types.boolOrUnset;
			command = commands: key: commandGenerators.boolCommand (commands key);
		};

	mkEnumOption = { key, description, commands, valueMap, default ? null, perUser ? true }:
		mkPlistOption { inherit key description commands default perUser; } {
			option.type = types.enumOrUnset (lib.attrNames valueMap);
			command = commands: key: commandGenerators.enumToIntCommand (commands key) valueMap;
		};

  # Bitmask option factory
  mkBitmaskOption = { key, description, commands, mapping, default ? null, perUser ? true }:
    mkPlistOption { inherit key description commands default perUser; } {
      option = {
        type = types.unsetOrBitmask mapping;
        apply = value:
          if builtins.isNull value then null
          else if value == "unset" then "unset"
          else calculateBitmask mapping value;
      };
      command = commands: key: commandGenerators.bitmaskCommand (commands key);
    };

  # Custom option factory for special cases
  mkCustomOption = { key, description, commands, optionConfig, commandFn, default ? null, perUser ? true }:
    mkPlistOption { inherit key description commands default perUser; } {
      option = optionConfig;
      command = commands: key: commandFn (commands key);
    };
}
