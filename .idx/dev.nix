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

    # --- Flutter / Desktop deps ---
    pkgs.gtk3
    pkgs.lzma

    # --- Web & Cloud ---
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
            "cd web-client && python3 -m http.server $PORT"
          ];
          manager = "web";
        };

        app = {
          command = [
            "sh"
            "-c"
            "cd mobile_app && flutter run -d web-server --web-port $PORT --web-hostname 0.0.0.0"
          ];
          manager = "web";
        };
      };
    };
  };
}
