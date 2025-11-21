{
  description = "ElixirTutor development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Elixir and Erlang
            elixir
            erlang

            # PostgreSQL
            postgresql

            # Node.js for assets
            nodejs
          ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
            # Build tools (Linux only)
            inotify-tools # for Phoenix live reload
          ];

          shellHook = ''
            # Create postgres data directory if it doesn't exist
            export PGDATA="$PWD/.postgres"
            export PGHOST="$PWD/.postgres"
            export PGDATABASE="elixir_tutor_dev"
            export DATABASE_URL="postgresql://localhost/elixir_tutor_dev?host=$PGDATA"

            # Initialize postgres if needed
            if [ ! -d "$PGDATA" ]; then
              echo "Initializing PostgreSQL database..."
              initdb -U postgres
              echo "unix_socket_directories = '$PGDATA'" >> $PGDATA/postgresql.conf
              echo "listen_addresses = ${"'"}${"'"}" >> $PGDATA/postgresql.conf
            fi

            # Start postgres in the background if not running
            if ! pg_isready -h "$PGDATA" > /dev/null 2>&1; then
              echo "Starting PostgreSQL..."
              pg_ctl -l $PGDATA/logfile start
            fi

            echo "PostgreSQL is running at $PGDATA"
            echo "Development environment ready!"
          '';
        };
      });
}
