{
  inputs.texshell.url = "github:jorsn/texshell.nix";

  outputs = { texshell, ... }@inputs:
    {
      inherit (texshell) packages apps;
    };
}
