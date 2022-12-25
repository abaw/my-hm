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
    initExtraFirst = ''
      # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
      # Initialization code that may require console input (password prompts, [y/n]
      # confirmations, etc.) must go above this block; everything else may go below.
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi
    '';

    initExtra = ''
      source ${./p10k.zsh}

      function pcd() { cd ''${PWD%/$1/*}/$1  }
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
