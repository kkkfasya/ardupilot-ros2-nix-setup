# Setup ROS 2 Jazzy + ArduPilot SITL + Gazebo Harmonic + MAVROS dengan Nix

Panduan ini dipakai untuk pelatihan Vision & Control Programmer Gamaforce 2027. Branch `nix` memakai flake, jadi ROS 2 Jazzy, Gazebo Harmonic, MAVROS, Python ArduPilot, JDK 17, dan Gradle tidak dipasang lewat apt. Semua versi dikunci di `flake.lock`.

Yang sudah diuji adalah Ubuntu 24.04 dengan Nix 2.35 dan shell bash atau zsh. Prasyaratnya hanya Nix dengan dukungan flakes dan git. Sisakan ruang disk sekitar 15-20 GB karena build ArduPilot dan micro_ros_agent besar. Kalau laptop mudah hang, jalankan earlyoom di luar shell Nix dan pantau memori dengan htop.

Masuk ke shell dengan `git switch nix` lalu `nix develop` di folder repositori ini. Semua perintah di bawah dijalankan di dalam shell tersebut.

Pertama siapkan workspace dan sumber kode:

```bash
ardu_ws_init
ardu_models_init
ardu_build
```

`ardu_ws_init` membuat `~/sim/ardu_ws` berisi symlink ke repositori yang dikunci sebagai input flake. `ardu_models_init` mengunduh SITL_Models karena repo data itu sengaja tidak dijadikan input flake; jalankan sekali saja dan butuh internet. `ardu_build` menjalankan `colcon build --packages-up-to ardupilot_dds_tests --parallel-workers 1`. Kalau build terhenti, jalankan perintah yang sama untuk melanjutkan. Kalau perlu mulai dari nol, hapus `build install log` di `~/sim/ardu_ws` sebelum membangun ulang.

Jalankan tiga terminal terpisah, masing-masing masuk dulu ke `nix develop`:

```bash
gz_sim_run
sitl_run
mavros_run
```

`gz_sim_run` membuka Gazebo dengan dunia `iris_runway.sdf`. `sitl_run` menjalankan ArduCopter lewat `sim_vehicle.py` dengan `gazebo-iris` dan MAVProxy. `mavros_run` menghubungkan MAVROS lewat UDP 14550. Di konsol MAVProxy, tunggu sampai ada `EKF3 IMU origin set` sebelum mengetik `mode guided`, `arm throttle`, dan `takeoff 5`. Drone di Gazebo harus ikut naik.

Gunakan port 14550. Port 14551 membuat MAVROS tidak menerima paket, dengan gejala `VER: ... timeout` dan peringatan soal `AUTOPILOT_VERSION`. Kalau MAVROS diam, ketik `output` di konsol MAVProxy untuk melihat tujuan keluaran, atau tambahkan dengan `output add 127.0.0.1:14550`.

Di terminal lain, jalankan `sim_env` lalu cek koneksi:

```bash
ros2 topic echo /mavros/imu/data --once
ros2 service list | grep -E 'set_mode|arming|takeoff'
```

`sim_env` memuat `install/setup.*` hasil build dan menambahkan path model Gazebo ke `GZ_SIM_RESOURCE_PATH`, termasuk path SITL_Models. Nama service untuk arm, ganti mode, takeoff, dan parameter sebaiknya dicek dari daftar service di laptop sendiri.

Pemeriksaan tanpa menginstal atau membangun apa pun:

```bash
nix flake check --no-build
nix build --dry-run .#devShells.x86_64-linux.default
```

Yang belum otomatis adalah dataset GeographicLib untuk MAVROS. Kalau MAVROS memerlukannya, siapkan dataset itu sendiri dan arahkan `GEOGRAPHICLIB_DATA` ke lokasinya. Sumber Micro-XRCE-DDS-Gen sudah tersedia di `$MICRO_XRCE_DDS_GEN_SRC` bersama JDK 17 dan Gradle dari shell; bangun dengan Gradle kalau build ArduPilot memintanya.
