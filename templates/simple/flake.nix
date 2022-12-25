{
  description = "My home manager configuration";
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    home-manager = {
      url = github:nix-community/home-manager/master;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    my-hm = {
      url = github:abaw/my-hm;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, my-hm, ... }:
    {
      homeConfigurations = {
        USERNAME = home-manager.lib.homeManagerConfiguration {
          # Update x86_64-linux to other platform if necessary
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = my-hm.hmModules ++ [ ./home.nix ];
        };
      };
    };
}
