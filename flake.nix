{
  description = "ROS 2 Jazzy + ArduPilot SITL + Gazebo Harmonic + MAVROS (Nix flakes)";

  inputs = {
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/9a7c8789c4c7a617a9bad25133f12fe383e6b176";
    nixpkgs.follows = "nix-ros-overlay/nixpkgs";

    ardupilot = {
      url = "github:ArduPilot/ardupilot/fb773567896014da007bca58358704d4a0d8516f";
      flake = false;
    };
    ardupilot_gazebo = {
      url = "github:ArduPilot/ardupilot_gazebo/cc0290d964dfa373531963a8fc39093a0836af0a";
      flake = false;
    };
    ardupilot_gz = {
      url = "github:ArduPilot/ardupilot_gz/ba6f4e1910b5661af3905d263ea1b20e3fb4dc48";
      flake = false;
    };
    micro_ros_agent = {
      url = "github:micro-ROS/micro-ROS-Agent/7c932329ad5591ef23942ef1962534258c16b000";
      flake = false;
    };
    ros_gz = {
      url = "github:gazebosim/ros_gz/98b83c5a075f350c143b3b403fc4482ebed180c0";
      flake = false;
    };
    sdformat_urdf = {
      url = "github:ros/sdformat_urdf/36378d23ecac42945caf262763bdffd7995eeeee";
      flake = false;
    };
  };

  outputs = { self, nix-ros-overlay, nixpkgs, ardupilot, ardupilot_gazebo, ardupilot_gz, micro_ros_agent, ros_gz, sdformat_urdf }:
    nix-ros-overlay.inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ nix-ros-overlay.overlays.default ];
        };
        ros = pkgs.rosPackages.jazzy;

        empy3 = pkgs.python3Packages.buildPythonPackage {
          pname = "empy";
          version = "3.3.4";
          src = pkgs.fetchPypi {
            pname = "empy";
            version = "3.3.4";
            sha256 = "1cq1izl6l87i5i3vj0jcqfksh10kpiwpr2m19vgpj530bdw4kb3k";
          };
          pyproject = true;
          build-system = [ pkgs.python3Packages.setuptools ];
          doCheck = false;
        };

        arduPython = pkgs.python3.withPackages (py: [
          empy3
          py.lxml
          py.pymavlink
          py.pyserial
          py.geocoder
          py.ptyprocess
          py.dronecan
          py.matplotlib
          py.scipy
          py.opencv-python
          py.pyyaml
        ]);
      in {
        devShells.default = pkgs.mkShell {
          name = "ardupilot-sitl";
          packages = [
            (pkgs.colcon.withExtensions [ pkgs.python3Packages.colcon-alias ])
            arduPython
            pkgs.mavproxy
            pkgs.geographiclib
            pkgs.sfml
            pkgs.xterm
            (ros.buildEnv {
              underlay = true;
              paths = [
                ros.desktop
                ros.ros-core
                ros.ament-cmake-core
                ros.python-cmake-module
                ros.ros-gz
                ros.gz-launch-vendor
                ros.mavros
                ros.mavros-extras
              ];
            })
          ];
          shellHook = ''
            export GZ_VERSION=harmonic
            unset QT_QPA_PLATFORM

            export ARDUPILOT_SRC="${ardupilot}"
            export ARDUPILOT_GAZEBO_SRC="${ardupilot_gazebo}"
            export ARDUPILOT_GZ_SRC="${ardupilot_gz}"
            export MICRO_ROS_AGENT_SRC="${micro_ros_agent}"
            export ROS_GZ_SRC="${ros_gz}"
            export SDFORMAT_URDF_SRC="${sdformat_urdf}"
          '';
        };
      });

  nixConfig = {
    extra-substituters = [ "https://ros.cachix.org" ];
    extra-trusted-public-keys = [ "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo=" ];
  };
}
