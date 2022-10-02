{
  inputs.ancienTeX.url = "github:jorsn/ancienTeX.nix";

  outputs = { ancienTeX, ... }@inputs:
    {
      inherit (ancienTeX) packages apps;
    };
}
