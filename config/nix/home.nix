{ pkgs, ... }:

{
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";

  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  home.packages = [
    pkgs.neovim
    pkgs.tmux
  ];
}
