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

  # Web UI — dostępny na http://localhost:8080
  services.open-webui = {
    enable = true;
    host = "127.0.0.1";
    port = 8080;
    openFirewall = false;
    environment = {
      OLLAMA_BASE_URL = "http://127.0.0.1:11434";
      WEBUI_AUTH = "False"; # bez logowania — lokalny dostęp
    };
  };

  # Dostęp do GPU przez render group
  users.users.tpmajer.extraGroups = [ "render" ];
}
