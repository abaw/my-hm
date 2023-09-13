{ config, lib, pkgs, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
  flake = pkgs.my-hm-flake;
  emacsPkg = if isDarwin
             then pkgs.emacs29.overrideAttrs
               (old: {
                 patches = old.patches ++ [ ./patches/no-frame-refocus-cocoa.patch ];
               })
             else pkgs.emacs29;
  emacs = (pkgs.emacsPackagesFor emacsPkg).emacsWithPackages (epkgs: with epkgs; [
      vterm
      treesit-grammars.with-all-grammars
    ]);
  doom-emacs-src-dir = pkgs.applyPatches {
    name = "doom-emacs-src-dir";
    src = flake.inputs.doom-emacs;
  };
  doom-emacs-local-dir = "${config.xdg.dataHome}/doom-emacs/local";
  doom-emacs-profiles-dir = "${config.xdg.dataHome}/doom-emacs/profiles";
  user-emacs-dir = pkgs.runCommand "user-emacs-dir" { nativeBuildInputs = [ pkgs.xorg.lndir ]; } ''
    set -x
    mkdir doomemacs
    lndir -silent ${doom-emacs-src-dir} doomemacs
    mv doomemacs/profiles{,.orig}
    ln -sfn "${doom-emacs-profiles-dir}" doomemacs/profiles
    cp -R doomemacs/ $out
  '';
  doom-emacs = pkgs.runCommand "doom-emacs" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
      cp -R ${emacs}/ $out
      # code stolen from https://github.com/nix-community/nix-doom-emacs/blob/master/default.nix
      wrapEmacs() {
          local -a wrapArgs=(
              --set-default DOOMLOCALDIR ${doom-emacs-local-dir}
              --add-flags '--init-directory ${user-emacs-dir}'
          )
          wrapProgram "$1" "''${wrapArgs[@]}"
      }

      chmod +w $out/bin
      for prog in $out/bin/*; do
          wrapEmacs "$prog"
      done

      # Doom comes with some CLIs (org-tangle, org-capture, doom)
      for prog in ${doom-emacs-src-dir}/bin/*; do
          [ -x "$prog" ] && makeWrapper $prog $out/bin/"$(basename $prog)" --prefix PATH : "$out/bin"
      done

      if [[ -e $out/Applications ]]; then
        chmod +w "$out/Applications/Emacs.app/Contents/MacOS/"
        wrapEmacs "$out/Applications/Emacs.app/Contents/MacOS/Emacs"
      fi
  '';

  cfg = config.my-hm.emacs;
  relToDoomD = file: cfg.doomDirectory + "/${file}";
in
with lib;
{
  options.my-hm.emacs = {
    enable = mkEnableOption "my-hm's emacs configuration";

    doomDirectory = mkOption {
      description = ''
        The doom.d directory to use.
      '';
      type = types.path;
      default = ./doom.d;
    };

    extraConfig = mkOption {
      description = ''
          Extra lines to append to doom.d/config.el.
        '';
      type = types.lines;
      default = "";
    };

    extraPackages = mkOption {
      description = ''
          Extra lines to append to doom.d/packages.el.
        '';
      type = types.lines;
      default = "";
    };
  };
  config = lib.mkIf cfg.enable
    (lib.mkMerge
      [
        {
          home.file =
            let
              configForVterm = lib.optionalString config.programs.zsh.enable ''
              (after! vterm
                  (setq vterm-shell "${pkgs.zsh}/bin/zsh"))
            '';
              extraConfig = pkgs.writeText "extraConfig" (configForVterm + ''
                ;; extraConfig
                ${cfg.extraConfig}
              '');
              extraPackages = pkgs.writeText "extraPackages" ''
                ;; extraPackages
                ${cfg.extraPackages}
              '';
            in
              {
                ".doom.d/init.el".source = relToDoomD "init.el";
                ".doom.d/config.el".source = pkgs.concatText "config.el"
                  [ (relToDoomD "config.el") extraConfig ];
                ".doom.d/packages.el".source = pkgs.concatText "packages.el"
                  [ (relToDoomD "packages.el") extraPackages ];
              };

          home.activation.my-hm-setup-doomemacs = hm.dag.entryBetween ["reloadSystemd"] ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p ${doom-emacs-local-dir}
      $DRY_RUN_CMD mkdir -p ${doom-emacs-profiles-dir}
      $DRY_RUN_CMD env PATH="${pkgs.git}/bin:$PATH" ${doom-emacs}/bin/doom sync -e
    '';

          home.packages = with pkgs; [
            (ripgrep.override { withPCRE2 = true; })
            fd
            (aspellWithDicts (d: [d.en]))
            ccls
            pyright
            python3.pkgs.isort
            doom-emacs
          ];
        }

        (lib.mkIf config.programs.zsh.enable
          {
            programs.zsh.initExtra = ''
      # vterm integration: report current directory to terminal
      vterm_printf() {
          if [ -n "$TMUX" ] && ([ "''${TERM%%-*}" = "tmux" ] || [ "''${TERM%%-*}" = "screen" ] ); then
              # Tell tmux to pass the escape sequences through
              printf "\ePtmux;\e\e]%s\007\e\\" "$1"
          elif [ "''${TERM%%-*}" = "screen" ]; then
              # GNU screen (screen, screen-256color, screen-256color-bce)
              printf "\eP\e]%s\007\e\\" "$1"
          else
              printf "\e]%s\e\\" "$1"
          fi
      }

      chpwd() {
          vterm_printf "51;A$(whoami)@$(hostname):$(pwd)";
      }
    '';
          }
        )

        (lib.mkIf isLinux {
          systemd.user.services.emacs = {
            Unit.Description = "Start emacs server";
            Service = {
              Type = "simple";
              ExecStart = "${config.home.homeDirectory}/.nix-profile/bin/emacs --fg-daemon -nw";
              ExecStop = "${config.home.homeDirectory}/.nix-profile/bin/emacsclient --eval \"(kill-emacs)\"";
              Restart = "on-failure";
              RestartSec = 5;
            };
            Install.WantedBy = [ "default.target" ];
          };
        })
      ]);
}
