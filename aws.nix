{ config, lib, pkgs, ... }:

{
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "ssm-session-manager-plugin"
  ];

  home.packages = with pkgs; [
    awscli2
    git-remote-codecommit
    ssm-session-manager-plugin
  ];

  programs.git = {
    # settings for aws codecommit
    extraConfig = {
      credential = {
          helper = "!aws codecommit credential-helper $@";
          UseHttpPath = "true";
      };
      protocol.codecommit.allow = "always";
    };
  };
}
