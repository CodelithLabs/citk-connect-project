{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {

  ############################################
  ## 🟢 LEVEL 1: EASY (Core Dev Environment)
  ############################################
  buildInputs = [

    # --- Languages ---
    pkgs.python3
    pkgs.nodejs
    pkgs.dart
    pkgs.flutter
    pkgs.jdk17

    # --- Basic Build Tools ---
    pkgs.git
    pkgs.cmake
    pkgs.ninja
    pkgs.gcc
    pkgs.pkg-config

    # --- Flutter Desktop Support ---
    pkgs.gtk3
    pkgs.lzma

    # --- Utilities ---
    pkgs.curl
    pkgs.wget
    pkgs.unzip
    pkgs.zip
  ]

  ############################################
  ## 🟡 LEVEL 2: HARD (Full-Stack Developer)
  ## 👉 Uncomment when ready
  ############################################
  ++ [

    # --- Backend Languages ---
    pkgs.go
    pkgs.rustc
    pkgs.cargo

    # --- Databases (CLI tools, not servers) ---
    pkgs.sqlite
    pkgs.redis
    pkgs.postgresql
    pkgs.mysql80

    # --- Debugging & Profiling ---
    pkgs.gdb
    pkgs.lldb
    pkgs.strace
    pkgs.valgrind

    # --- Web / Cloud ---
    pkgs.firebase-tools
    pkgs.awscli2
    pkgs.google-cloud-sdk
  ]

  ############################################
  ## 🔴 LEVEL 3: PRO (Systems + DevOps)
  ## 👉 Uncomment ONLY when confident
  ############################################
  ++ [

    # --- Containers ---
    pkgs.docker
    pkgs.podman

    # --- Kubernetes ---
    pkgs.kubectl
    pkgs.helm
    pkgs.minikube

    # --- Infrastructure as Code ---
    pkgs.terraform
    pkgs.ansible

    # --- Networking / Security ---
    pkgs.openssl
    pkgs.httpie
    pkgs.nmap

    # --- Code Quality ---
    pkgs.clang-tools
    pkgs.shellcheck
  ];

  ############################################
  ## 🔧 ENVIRONMENT SETUP
  ############################################
  shellHook = ''
    export CMAKE_GENERATOR=Ninja
    export FLUTTER_ROOT=${pkgs.flutter}
    export JAVA_HOME=${pkgs.jdk17}

    echo ""
    echo "🚀 Development Shell Ready"
    echo "──────────────────────────"
    echo "✔ Flutter   : $(flutter --version | head -n 1)"
    echo "✔ Dart      : $(dart --version 2>/dev/null)"
    echo "✔ Node.js   : $(node --version)"
    echo "✔ Python    : $(python3 --version)"
    echo "✔ Java      : $(java -version 2>&1 | head -n 1)"
    echo ""
    echo "🧠 Tip: Uncomment HARD / PRO sections as you level up"
    echo ""
  '';
}
