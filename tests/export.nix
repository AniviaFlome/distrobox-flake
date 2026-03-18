{ pkgs }:

let
  testLib = import ./lib.nix { inherit pkgs; };
  inherit (testLib) mkEvalModule assertMsg;

  emptyConfig = mkEvalModule {
    programs.distrobox-flake.enable = true;
    programs.distrobox-flake.containers.test = { };
  };

  appsConfig = mkEvalModule {
    programs.distrobox-flake.enable = true;
    programs.distrobox-flake.containers.test.export.apps = [
      "firefox"
      "org.gnome.Calculator"
    ];
  };

  binariesConfig = mkEvalModule {
    programs.distrobox-flake.enable = true;
    programs.distrobox-flake.containers.test.export.binaries = {
      "/usr/bin/htop" = "~/.local/bin";
      "/usr/bin/nvim" = "~/.local/bin";
    };
  };

  bothConfig = mkEvalModule {
    programs.distrobox-flake.enable = true;
    programs.distrobox-flake.containers.test.export = {
      apps = [ "mpv" ];
      binaries."/usr/bin/htop" = "~/.local/bin";
    };
  };

  emptyHooks = emptyConfig.programs.distrobox.containers.test.init_hooks or [ ];
  appsHooks = appsConfig.programs.distrobox.containers.test.init_hooks or [ ];
  binariesHooks = binariesConfig.programs.distrobox.containers.test.init_hooks or [ ];
  bothHooks = bothConfig.programs.distrobox.containers.test.init_hooks or [ ];

  tests = [
    (assertMsg (emptyHooks == [ ]) "empty export config should produce no hooks")

    (assertMsg (builtins.length appsHooks == 2) "two apps should produce 2 hooks")
    (assertMsg (builtins.elem "distrobox-export --app firefox" appsHooks) "firefox app hook should be present")
    (assertMsg (builtins.elem "distrobox-export --app org.gnome.Calculator" appsHooks) "org.gnome.Calculator app hook should be present")

    (assertMsg (builtins.length binariesHooks == 2) "two binaries should produce 2 hooks")
    (assertMsg (builtins.elem "distrobox-export --bin /usr/bin/htop --export-path ~/.local/bin" binariesHooks) "htop binary hook should be present")
    (assertMsg (builtins.elem "distrobox-export --bin /usr/bin/nvim --export-path ~/.local/bin" binariesHooks) "nvim binary hook should be present")

    (assertMsg (builtins.length bothHooks == 2) "one app + one binary should produce 2 hooks")
    (assertMsg (builtins.elem "distrobox-export --app mpv" bothHooks) "mpv app hook should be present in combined config")
    (assertMsg (builtins.elem "distrobox-export --bin /usr/bin/htop --export-path ~/.local/bin" bothHooks) "htop binary hook should be present in combined config")
  ];

  allPass = builtins.all (x: x) tests;
in
if allPass then
  pkgs.runCommand "test-export" { } ''
    echo "All tests passed" > $out
  ''
else
  builtins.abort "Tests failed"
