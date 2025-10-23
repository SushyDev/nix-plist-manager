# nix-plist-manager

A Nix module for managing macOS system settings through plist files. This module provides a declarative way to configure various macOS system preferences using nix-darwin.

![System Settings compared to nix-plist-manager](nix-plist-manager.webp)

## Dependencies

This module requires [nix-darwin](https://github.com/nix-darwin/nix-darwin) to function properly.

## Installation

Add this flake to your nix-darwin configuration:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-plist-manager.url = "github:sushydev/nix-plist-manager";
  };

  outputs = { self, nix-darwin, nix-plist-manager, ... }: {
    darwinConfigurations."your-hostname" = nix-darwin.lib.darwinSystem {
      modules = [
        nix-plist-manager.darwinModules.default
        ./configuration.nix
      ];
    };
  };
}
```

## Usage

Please check [sushydev.github.io/nix-plist-manager](https://sushydev.github.io/nix-plist-manager/) for all available options
