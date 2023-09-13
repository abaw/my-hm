{
  description = "My home-manager modules";
  inputs = {
    flake-compat = {
      url = github:edolstra/flake-compat;
      flake = false;
    };
    nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    doom-emacs = {
      url = github:doomemacs/doomemacs/v2.0.9;
      flake = false;
    };
    zsh-autosuggestions = {
      url = github:zsh-users/zsh-autosuggestions/master;
      flake = false;
    };
  };

  outputs = { self, nixpkgs, zsh-autosuggestions, ... }: {
    hmModules = [
      ./general.nix
      ./zsh.nix
      ({ config, pkgs, ...  }:
        let
          my-hm-flake =
            (import
              (let lock = with builtins; fromJSON (readFile ./flake.lock); in
               builtins.fetchTarball {
                 url = "https://github.com/edolstra/flake-compat/archive/${lock.nodes.flake-compat.locked.rev}.tar.gz";
                 sha256 = lock.nodes.flake-compat.locked.narHash;
               })
              { src = ./.;  }).defaultNix;
        in { nixpkgs.overlays = [ (super: self: { inherit my-hm-flake; })]; })
      ./emacs.nix
      ./aws.nix
    ];

    templates = {
      simple = {
        path = ./templates/simple;
        description = "A simple flake to use my-hm";
      };
    };
  };
}
