# ~/.nixos/llm.nix

{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan;
    host = "127.0.0.1";
    port = 11434;
    openFirewall = false;
  };

  # Web UI — available at http://localhost:8080
  # Temporarily disabled — open-webui 0.9.5 build broken in nixos-unstable
  # (missing @internationalized/date peer dep), fixed in PR #523213, re-enable after nix flake update
  # services.open-webui = {
  #   enable = true;
  #   host = "127.0.0.1";
  #   port = 8080;
  #   openFirewall = false;
  #   environment = {
  #     OLLAMA_BASE_URL = "http://127.0.0.1:11434";
  #     WEBUI_AUTH = "False"; # no login — local access only
  #   };
  # };

  # Dostęp do GPU przez render group
  users.users.tpmajer.extraGroups = [ "render" ];
}
