{
  description = "ROS 2 Jazzy + ArduPilot SITL + Gazebo Harmonic + MAVROS (Nix flakes)";

  inputs = {
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/9a7c8789c4c7a617a9bad25133f12fe383e6b176";
    nixpkgs.follows = "nix-ros-overlay/nixpkgs";
  };

  outputs = { self, nix-ros-overlay, nixpkgs }:
    nix-ros-overlay.inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ nix-ros-overlay.overlays.default ];
        };
        ros = pkgs.rosPackages.jazzy;
      in {
        devShells.default = pkgs.mkShell {
          name = "ardupilot-sitl";
          packages = [
            (pkgs.colcon.withExtensions [ pkgs.python3Packages.colcon-alias ])
            (ros.buildEnv {
              underlay = true;
              paths = [
                ros.desktop
                ros.ros-core
                ros.ament-cmake-core
                ros.python-cmake-module
                ros.ros-gz
                ros.gz-launch-vendor
              ];
            })
          ];
          shellHook = ''
            export GZ_VERSION=harmonic
            unset QT_QPA_PLATFORM
          '';
        };
      });

  nixConfig = {
    extra-substituters = [ "https://ros.cachix.org" ];
    extra-trusted-public-keys = [ "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo=" ];
  };
}
