# A script from ../scripts as a command, shellchecked at build. No bash options
# are added: a script that wants `set -e` says so itself.

{ pkgs }:

name:
{
  inputs ? [ ],
  env ? null,
}:
pkgs.writeShellApplication {
  inherit name;
  runtimeInputs = inputs;
  runtimeEnv = env;
  bashOptions = [ ];
  text = builtins.readFile ../scripts/${name}.sh;
}
