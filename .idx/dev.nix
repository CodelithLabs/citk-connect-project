# To learn more about how to use Nix to configure your environment
# see: https://firebase.google.com/docs/studio/customize-workspace
{ pkgs, ... }: {
  # Which nixpkgs channel to use.
  channel = "stable-24.05"; # or "unstable"

  # Use https://search.nixos.org/packages to find packages
  packages = [
    pkgs.python3
  ];

  # Sets environment variables in the workspace
  env = {};
  idx = {
    # Search for the extensions you want on https://open-vsx.org/ and use "publisher.id"
    extensions = [
      # "vscodevim.vim"
    ];

    # Enable previews
    previews = {
      enable = true;
      previews = {
        web = {
          command = ["python", "-m", "http.server", "$PORT", "--directory", "web-client"];
          manager = "web";
        };
        app = {
          command = ["sh", "-c", "cd mobile_app && flutter run -d web-server --web-port $PORT"];
          manager = "web";
        };
      };
    };
  };
}
