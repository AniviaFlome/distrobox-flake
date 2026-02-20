_:
{
  projectRootFile = "treefmt.nix";

  programs = {
    nixfmt.enable = true;
    deadnix.enable = true;
    statix.enable = true;
    mdformat.enable = true;
  };
}
