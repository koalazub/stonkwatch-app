{
  description = "stonkwatch-app — AI-native iOS companion for StonkWatch";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "aarch64-darwin" "x86_64-darwin" ] (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # The Swift version we target — change this to update the whole team
        swiftVersion = "6.3-snapshot";
      in
      {
        devShells.default = pkgs.mkShell {
          name = "stonkwatch-app";

          packages = with pkgs; [
            # Linting (swift format ships with the Swift toolchain via Swiftly)
            swiftlint

            # Build output formatting
            xcbeautify

            # API debugging
            jq
            grpcurl

            # Git & GitHub
            gh

            # Search
            ripgrep
            fd
          ];

          shellHook = ''
            SWIFTLY_HOME="''${SWIFTLY_HOME_DIR:-$HOME/.swiftly}"
            SWIFTLY_BIN="$SWIFTLY_HOME/bin/swiftly"
            SWIFTLY_ENV="$SWIFTLY_HOME/env.sh"
            SWIFT_VERSION="${swiftVersion}"

            # --- 1. Install Swiftly if missing ---
            if [ ! -x "$SWIFTLY_BIN" ]; then
              echo ""
              echo "  Swiftly not found — installing..."
              TMPDIR="$(mktemp -d)"
              curl -sL -o "$TMPDIR/swiftly.pkg" https://download.swift.org/swiftly/darwin/swiftly.pkg
              installer -pkg "$TMPDIR/swiftly.pkg" -target CurrentUserHomeDirectory >/dev/null 2>&1
              "$SWIFTLY_BIN" init --quiet-shell-followup 2>/dev/null
              rm -rf "$TMPDIR"
              echo "  Swiftly installed."
            fi

            # --- 2. Source Swiftly env (puts swiftly + active toolchain on PATH) ---
            if [ -f "$SWIFTLY_ENV" ]; then
              . "$SWIFTLY_ENV"
            fi

            # --- 3. Install the target Swift version if not present ---
            if ! swiftly list 2>/dev/null | grep -q "$SWIFT_VERSION"; then
              echo "  Swift $SWIFT_VERSION not found — installing via Swiftly..."
              swiftly install "$SWIFT_VERSION" --post-install-file=/dev/null 2>/dev/null
              swiftly use "$SWIFT_VERSION" 2>/dev/null
              # Re-source env to pick up the new toolchain
              . "$SWIFTLY_ENV"
              echo "  Swift $SWIFT_VERSION installed."
            fi

            echo ""
            echo "  stonkwatch-app dev shell"
            echo "  Swift:        $(swift --version 2>/dev/null | head -1 || echo 'not installed')"
            echo "  Xcode:        $(xcodebuild -version 2>/dev/null | head -1 || echo 'not installed')"
            echo "  swift format: $(swift format --version 2>/dev/null || echo 'n/a')"
            echo "  SwiftLint:    $(swiftlint version 2>/dev/null)"
            echo ""
          '';

          # Use the system Xcode toolchain — Nix cannot provide Xcode
          DEVELOPER_DIR = "/Applications/Xcode.app/Contents/Developer";
        };
      });
}
