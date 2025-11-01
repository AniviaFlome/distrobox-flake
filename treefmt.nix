_:

{
  # Used for `nix fmt`
  projectRootFile = "flake.nix";

  programs = {
    nixfmt.enable = true;
    statix.enable = true;
    deadnix.enable = true;
    prettier.enable = true;
    shfmt = {
      enable = true;
      indent_size = 2;
    };
  };
}
