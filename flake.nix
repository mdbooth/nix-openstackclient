{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/22.11";
    mach-nix.url = "mach-nix/3.5.0";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {self, nixpkgs, mach-nix, flake-utils }:
    let
      l = nixpkgs.lib // builtins;
      supportedSystems = flake-utils.lib.defaultSystems;
      forAllSystems = f: l.genAttrs supportedSystems
        (system: f system (import nixpkgs {inherit system;}));
      openstackPython = forAllSystems (system: pkgs: mach-nix.lib."${system}".mkPython {
        python = "python39";

        requirements = ''
          osc-placement
          python-cyborgclient
          python-manilaclient
          python-octaviaclient
          python-openstackclient
          setuptools
        '';
      });
      execs = [ "cinder" "cyborg" "manila" "neutron" "nova" "openstack" ];
      apps = l.genAttrs execs (name: "${name}") // { default = "openstack"; };
    in
    {
      apps = l.genAttrs supportedSystems (system:
        l.genAttrs (builtins.attrNames apps) (app:
          {
              type = "app";
              program = "${openstackPython.${system}}/bin/${apps.${app}}";
          }
        )
      );
      defaultPackage = openstackPython;
    };
}
