{ pkgs, ... }: {
  channel = "stable-24.05";

  packages = [
    # ─── Core Languages ─────────────────────────
    pkgs.python3
    pkgs.nodejs
    pkgs.dart
    pkgs.flutter
    pkgs.jdk17

    # ─── Android / Emulator ────────────────────
    pkgs.android-tools
    pkgs.gradle

    # ─── Build Tools ───────────────────────────
    pkgs.cmake
    pkgs.ninja
    pkgs.clang
    pkgs.gcc
    pkgs.pkg-config

    # ─── Flutter Desktop ───────────────────────
    pkgs.gtk3
    pkgs.lzma

    # ─── Firebase ──────────────────────────────
    pkgs.firebase-tools

    # ─── Utilities ─────────────────────────────
    pkgs.git
    pkgs.curl
    pkgs.wget
    pkgs.unzip
    pkgs.zip
  ];

  env = {
    # ─── Build ─────────────────────────────────
    CMAKE_GENERATOR = "Ninja";

    # ─── Java / Android ────────────────────────
    JAVA_HOME = pkgs.jdk17.home;
    ANDROID_HOME = "/home/user/android-sdk";
    ANDROID_SDK_ROOT = "/home/user/android-sdk";

    # ─── App Environment ───────────────────────
    APP_ENV = "dev"; # change to "prod" for production

    # ─── Firebase (DEV) ────────────────────────
    FIREBASE_PROJECT_ID = "citk-connect-dev";
    FIREBASE_AUTH_DOMAIN = "citk-connect-dev.firebaseapp.com";
    FIREBASE_FIRESTORE_DB = "(default)";
  };

  idx = {
    extensions = [
      "Dart-Code.flutter"
      "Dart-Code.dart-code"
      "firebase.vscode-firebase-explorer"
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
