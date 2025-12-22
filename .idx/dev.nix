{ pkgs, ... }: {
  channel = "stable-24.05";

  packages = [
    # --- Core Languages ---
    pkgs.python3
    pkgs.nodejs
    pkgs.dart
    pkgs.flutter
    pkgs.jdk17

    # --- Build Tools ---
    pkgs.cmake
    pkgs.ninja
    pkgs.clang
    pkgs.gcc
    pkgs.pkg-config

    # --- Flutter Desktop Deps ---
    pkgs.gtk3
    pkgs.lzma

    # --- Firebase / Cloud ---
    pkgs.firebase-tools

    # --- Utilities ---
    pkgs.git
    pkgs.curl
    pkgs.wget
    pkgs.unzip
    pkgs.zip
  ];

  env = {
    CMAKE_GENERATOR = "Ninja";
    JAVA_HOME = pkgs.jdk17.home;
  };

  idx = {
    extensions = [
      "Dart-Code.flutter"
      "Dart-Code.dart-code"
    ];

    previews = {
      enable = true;

      previews = {
        web = {
          command = [
            "sh"
            "-c"
            "cd web-client && npm install && npm run dev"
          ];
          manager = "web";
        };
      };
    };
  };
}
