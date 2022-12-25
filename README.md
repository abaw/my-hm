# Introduction

This repository contains home-manager modules for my personal configurations.
You could use the following commands to start using it.

``` shell
# create a flake from the template
nix flake new --template github:abaw/my-hm#simple home-config

# replace USERNAME to your user name. Here we use "ubuntu" as an example.
sed -i 's/USERNAME/ubuntu/' home-config/*.nix 

# switch to the configuration by the following command if you have home-manager installed.
home-manager switch --flake $(readlink -f home-config)
# otherwise, use this command instead:
nix run nixpkgs\#home-manager -- switch --flake $(readlink -f home-config)
```

