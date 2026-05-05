# Docker Engine and Docker Compose Installer for Ubuntu

This Bash script installs Docker Engine and/or Docker Compose on Ubuntu. It is version-agnostic: instead of hardcoding a single Ubuntu release or CPU architecture, it detects the Ubuntu codename from `/etc/os-release`, detects the apt architecture with `dpkg`, and validates that Docker publishes packages for that codename, architecture, and channel before installing.

Docker only publishes packages for supported release and architecture combinations. For older Ubuntu releases, derivatives, mirrors, or advanced environments, use the override flags below.

## Prerequisites

Run the script on Ubuntu or an Ubuntu-like distribution with administrative privileges. The script uses `sudo` when it is not run as root.

## Usage

Make the script executable:

```bash
chmod +x docker-install.sh
```

Install Docker Engine and Docker Compose:

```bash
./docker-install.sh --with-docker --with-compose
```

Install Docker only:

```bash
./docker-install.sh --with-docker
```

Install Docker Compose only:

```bash
./docker-install.sh --with-compose
```

By default, `--with-compose` installs the current Docker Compose v2 plugin from Docker's apt repository. Use `docker compose ...` after installation.

## Command Line Arguments

- `--with-docker`: Installs Docker Engine.
- `--with-compose`: Installs Docker Compose.
- `--channel <stable|test|nightly>`: Selects the Docker apt repository channel. Default: `stable`.
- `--docker-version <version>`: Installs a specific `docker-ce` and `docker-ce-cli` apt version.
- `--compose-method <plugin|standalone|both>`: Selects how Compose is installed. Default: `plugin`.
- `--compose-version <version>`: Installs a specific standalone Compose version, such as `v2.x.y`.
- `--ubuntu-codename <codename>`: Overrides Ubuntu codename detection, such as `noble`, `jammy`, or `focal`.
- `--repo-url <url>`: Uses a custom Docker apt repository URL or mirror.
- `--skip-repo-check`: Skips the preflight check for Docker packages in the selected repository.
- `--no-remove-conflicts`: Keeps potentially conflicting packages instead of removing them first.
- `--no-usermod`: Does not add the invoking user to the `docker` group.
- `-h`, `--help`: Shows script help.

## Examples

Install Docker and Compose on the detected Ubuntu release:

```bash
./docker-install.sh --with-docker --with-compose
```

Install from Docker's `test` channel:

```bash
./docker-install.sh --with-docker --with-compose --channel test
```

Override codename detection for an Ubuntu derivative:

```bash
./docker-install.sh --with-docker --with-compose --ubuntu-codename noble
```

Install the legacy standalone `docker-compose` command:

```bash
./docker-install.sh --with-compose --compose-method standalone
```

Install both the Compose plugin and standalone binary:

```bash
./docker-install.sh --with-docker --with-compose --compose-method both
```

## Verification

After installation, verify the installed commands:

```bash
docker --version
docker compose version
```

If you installed standalone Compose, verify it with:

```bash
docker-compose --version
```

If the script added your user to the `docker` group, log out and back in before running Docker commands without `sudo`.

## License

This script is licensed under the MIT License. See the `LICENSE` file for details.

## Disclaimer

This script is provided as-is and without any warranty. Use at your own risk. The author is not responsible for any damage or loss caused by the use of this script.
