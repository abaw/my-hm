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
      direnv
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
  }
  (lib.mkIf isDarwin {
    home.packages = with pkgs; [ skhd lorri ];
    home.file.".skhdrc".source = ./dot_skhdrc;
    launchd.agents = let
      mkAgent = name: args: {
        enable = true;
        config = {
          ProgramArguments = args;
          WorkingDirectory = config.home.homeDirectory;
          RunAtLoad = true;
          KeepAlive = true;
          EnvironmentVariables = {
            SHELL = "/bin/dash";
            PATH = lib.concatStringsSep ":" [
              "${config.home.homeDirectory}/.nix-profile/bin"
              "/run/current-system/sw/bin"
              "/nix/var/nix/profiles/default/bin"
              "/usr/bin"
            ];
          };
          StandardOutPath = "/var/tmp/${name}.out.log";
          StandardErrorPath = "/var/tmp/${name}.err.log";
        };
      };
    in {
      skhd = mkAgent "skhd" [ "${config.home.homeDirectory}/.nix-profile/bin/skhd" ];
      lorri = mkAgent "lorri" [ "${config.home.homeDirectory}/.nix-profile/bin/lorri" "daemon" ];
    };
  })
  (lib.mkIf isLinux {
    services.lorri.enable = true;
  })

  (lib.mkIf config.programs.zsh.enable {
    programs.zsh.initExtra =
      ''eval "$(direnv hook zsh)"
      '';
  })
]
