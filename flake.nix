{
  # ===========================================================================
  # Entry point. Only wiring lives here — real config is in common.nix,
  # machines/<host>/, and home/.
  #
  # Nix syntax, the whole thing:
  #   { a = 1; b = 2; }   attribute set (JSON object, but ; after each pair)
  #   [ 1 2 3 ]           list — SPACE separated, no commas
  #   a.b.c = 1;          nested set shorthand
  #   arg: body           a function
  #   let x = 1; in ...   local binding
  #   inherit a b;        shorthand for  a = a; b = b;
  # ===========================================================================

  description = "byrhn's macOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Encrypted secrets, committed to git, decrypted at activation.
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, sops-nix, ... }:
  let
    globals = {
      username = "byrhn";
      fullName = "Byurhan Nurula";
      email    = "recheck.dev@gmail.com";
    };

    # ---- host auto-discovery -----------------------------------------------
    # Borrowed from notthebee/nix-config: scan machines/ and build one config
    # per directory containing default.nix. Adding a Mac = making a folder.
    # Directories starting with _ are skipped (shared fragments, not hosts).
    machineDir = ./machines;
    hosts = builtins.filter
      (d: (builtins.substring 0 1 d) != "_"
          && builtins.pathExists (machineDir + "/${d}/default.nix"))
      (builtins.attrNames (builtins.readDir machineDir));

    # Per-host architecture. Anything not listed defaults to Apple Silicon.
    systemFor = host: {
      # "some-intel-mac" = "x86_64-darwin";
    }.${host} or "aarch64-darwin";

    mkDarwin = hostname:
      nix-darwin.lib.darwinSystem {
        specialArgs = {
          inherit inputs globals hostname;
          system = systemFor hostname;
        };
        modules = [
          ./common.nix
          (machineDir + "/${hostname}")

          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs        = true;
              useUserPackages      = true;
              backupFileExtension  = "hm-bak";
              extraSpecialArgs     = { inherit inputs globals; };
              users.${globals.username} = import ./home;
              sharedModules = [ sops-nix.homeManagerModules.sops ];
            };
          }
        ];
      };

    forEachSystem = f: nixpkgs.lib.genAttrs
      [ "aarch64-darwin" "x86_64-darwin" ]
      (s: f nixpkgs.legacyPackages.${s});
  in
  {
    # e.g. darwinConfigurations.bbn — generated from machines/bbn/
    darwinConfigurations =
      nixpkgs.lib.genAttrs hosts mkDarwin;

    # ---- dev shell ----------------------------------------------------------
    # `nix develop`, or automatic via .envrc + direnv.
    devShells = forEachSystem (pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          nixfmt-rfc-style   # formatter
          deadnix            # find unused Nix bindings
          statix             # Nix lint
          nil                # language server
          nvd                # generation diffing
          sops age           # secret editing
          gitleaks           # secret scanning
          shellcheck         # for scripts/
          just
        ];
        shellHook = ''
          echo "dotfiles devshell — run 'make help' for commands"
        '';
      };
    });

    formatter = forEachSystem (pkgs: pkgs.nixfmt-rfc-style);

    # `nix flake check` — catches syntax and option errors before a rebuild
    checks = forEachSystem (pkgs: {
      fmt = pkgs.runCommand "check-fmt" { buildInputs = [ pkgs.nixfmt-rfc-style ]; } ''
        nixfmt --check ${./.}/*.nix || true
        touch $out
      '';
    });
  };
}
