{ config, lib, pkgs, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
in
lib.mkMerge [
  {
    home.packages = with pkgs; [
      htop
      bitwarden-cli
      # pandoc to pdf files
      pandoc texlive.combined.scheme-small
      jq
      cloc
      shellcheck
      tree
      bat
    ];

    programs.home-manager.enable = true;

    programs.git = {
      enable = true;
      extraConfig = {
        core = {
          pager = "less -FMRiX";
        } // lib.optionalAttrs isDarwin {
          sshCommand = "ssh"; # use system's ssh
        };
        push.default = "simple";
        color.ui = "auto";
        alias = {
          dag = "log --graph --format='format:%C(yellow)%h%C(reset) %C(blue)\"%an\" <%ae>%C(reset) %C(magenta)%cr%C(reset)%C(auto)%d%C(reset)%n%s' --date-order";
        };
      };

      lfs.enable = true;
    } // lib.optionalAttrs isDarwin {
      package = (pkgs.git.override({ osxkeychainSupport = false; })).overrideAttrs (_: { doInstallCheck = false; });
    };

    programs.tmux = {
      enable = true;
      prefix = "C-a";
      keyMode = "emacs";
      historyLimit = 100000;
      clock24 = true;
      terminal = "xterm-256color";
      extraConfig =
        ''
          bind a send-prefix

          # Last active window
          unbind l
          bind C-a last-window

          # More straight forward key bindings for splitting
          unbind %
          bind s split-window -h
          unbind '"'
          bind S split-window -v

          # renaming the window
          bind A command-prompt "renamew %%"

          # Highlighting the active window in status bar
          setw -g window-status-current-style bg=red

          # I don't want this "update-environment" feature.
          set -g update-environment ""
        '';
    };

    programs.bat = {
      enable = true;
      config = {
        theme = "zenburn";
      };
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  }
]
