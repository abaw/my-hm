{ config, lib, pkgs, ... }:
let
  flake = pkgs.my-hm-flake;
  omz-plugins = pkgs.linkFarm "plugins" [
    {
      name = "zsh-autosuggestions";
      path = flake.inputs.zsh-autosuggestions;
    }
  ];
  omz-custom-dir = pkgs.linkFarm "custom" [
    { name = "plugins"; path = omz-plugins; }
  ];
in
{
  home.packages = with pkgs; [
    zoxide
    fzf
  ];

  programs.zsh = {
    enable = true;
    envExtra = ''
    if [ -e /nix  ]; then
      nix_owner=$(${pkgs.coreutils}/bin/stat --format "%U" /nix)
      if [ "$nix_owner" = "${config.home.username}" ]; then
        # single-user NIX installation
        to_source=~/.nix-profile/etc/profile.d/nix.sh
      else
        # multi-user NIX installation
        to_source=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      fi
      unset nix_owner

      if [ -e "$to_source" ]; then
        . "$to_source"
      fi
      unset to_source
    fi
    '';
    initExtraFirst = ''
      # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
      # Initialization code that may require console input (password prompts, [y/n]
      # confirmations, etc.) must go above this block; everything else may go below.
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi

      # hack to workaround "nix shell" issue
      set -A nix_shell_paths
      for p in $path; do
          if [[ $p == /nix/store/* ]]; then
            nix_shell_paths+=($p)
          fi
      done
      PATH=$(echo $PATH|sed -e 's|/nix/store/[^:]*:||g')
      path=($nix_shell_paths[@] $path)
    '';

    initExtra = ''
      source ${./p10k.zsh}

      function pcd() { cd ''${PWD%/$1/*}/$1  }

      path=(~/.local/bin $path)
    '';

    plugins = [
      {
          name = "powerline10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        }
    ];
    oh-my-zsh = {
      enable = true;
      plugins = [
        "zoxide"
        "fzf"
        "zsh-autosuggestions"
      ];
      custom = "${omz-custom-dir}";
    };
  };
}
