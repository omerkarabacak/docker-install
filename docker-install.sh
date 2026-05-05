#!/usr/bin/env bash
set -Eeuo pipefail

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

DOCKER=false
COMPOSE=false
DOCKER_CHANNEL="stable"
DOCKER_VERSION=""
COMPOSE_METHOD="plugin"
COMPOSE_VERSION=""
UBUNTU_CODENAME_OVERRIDE=""
DOCKER_REPO_URL="https://download.docker.com/linux/ubuntu"
SKIP_REPO_CHECK=false
REMOVE_CONFLICTS=true
ADD_CURRENT_USER=true

usage() {
    cat <<'EOF'
Usage:
  ./docker-install.sh [options]

Required install choices:
  --with-docker                 Install Docker Engine.
  --with-compose                Install Docker Compose.

Optional settings:
  --channel <stable|test|nightly>
                                 Docker apt repository channel. Default: stable.
  --docker-version <version>     Install a specific docker-ce/docker-ce-cli apt version.
  --compose-method <method>      Compose install method: plugin, standalone, or both.
                                 Default: plugin.
  --compose-version <version>    Standalone Compose version, such as v2.x.y.
                                 If omitted, the latest GitHub release is used.
  --ubuntu-codename <codename>   Override Ubuntu codename detection, such as noble.
  --repo-url <url>               Override Docker's Ubuntu apt repository URL.
  --skip-repo-check              Skip the repository package availability check.
  --no-remove-conflicts          Do not remove conflicting Ubuntu/docker packages first.
  --no-usermod                   Do not add the invoking user to the docker group.
  -h, --help                     Show this help.

Examples:
  ./docker-install.sh --with-docker --with-compose
  ./docker-install.sh --with-docker --with-compose --ubuntu-codename noble
  ./docker-install.sh --with-compose --compose-method standalone
EOF
}

info() {
    printf '%b\n' "${GREEN}$*${NC}"
}

warn() {
    printf '%b\n' "${YELLOW}Warning: $*${NC}" >&2
}

die() {
    printf '%b\n' "${RED}Error: $*${NC}" >&2
    exit 1
}

run_as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --with-docker)
                DOCKER=true
                ;;
            --with-compose)
                COMPOSE=true
                ;;
            --channel)
                shift
                [ $# -gt 0 ] || die "--channel requires a value."
                DOCKER_CHANNEL="$1"
                ;;
            --channel=*)
                DOCKER_CHANNEL="${1#*=}"
                ;;
            --docker-version)
                shift
                [ $# -gt 0 ] || die "--docker-version requires a value."
                DOCKER_VERSION="$1"
                ;;
            --docker-version=*)
                DOCKER_VERSION="${1#*=}"
                ;;
            --compose-method)
                shift
                [ $# -gt 0 ] || die "--compose-method requires a value."
                COMPOSE_METHOD="$1"
                ;;
            --compose-method=*)
                COMPOSE_METHOD="${1#*=}"
                ;;
            --compose-version)
                shift
                [ $# -gt 0 ] || die "--compose-version requires a value."
                COMPOSE_VERSION="$1"
                ;;
            --compose-version=*)
                COMPOSE_VERSION="${1#*=}"
                ;;
            --ubuntu-codename)
                shift
                [ $# -gt 0 ] || die "--ubuntu-codename requires a value."
                UBUNTU_CODENAME_OVERRIDE="$1"
                ;;
            --ubuntu-codename=*)
                UBUNTU_CODENAME_OVERRIDE="${1#*=}"
                ;;
            --repo-url)
                shift
                [ $# -gt 0 ] || die "--repo-url requires a value."
                DOCKER_REPO_URL="${1%/}"
                ;;
            --repo-url=*)
                DOCKER_REPO_URL="${1#*=}"
                DOCKER_REPO_URL="${DOCKER_REPO_URL%/}"
                ;;
            --skip-repo-check)
                SKIP_REPO_CHECK=true
                ;;
            --no-remove-conflicts)
                REMOVE_CONFLICTS=false
                ;;
            --no-usermod)
                ADD_CURRENT_USER=false
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                die "Invalid argument: $1"
                ;;
        esac
        shift
    done
}

validate_args() {
    if ! $DOCKER && ! $COMPOSE; then
        die "No argument specified. Please specify --with-docker, --with-compose, or both."
    fi

    case "$DOCKER_CHANNEL" in
        stable|test|nightly) ;;
        *) die "--channel must be stable, test, or nightly." ;;
    esac

    case "$COMPOSE_METHOD" in
        plugin|standalone|both) ;;
        *) die "--compose-method must be plugin, standalone, or both." ;;
    esac

    if [ -n "$COMPOSE_VERSION" ] && [ "$COMPOSE_METHOD" = "plugin" ]; then
        die "--compose-version only applies when --compose-method is standalone or both."
    fi

    if [ -n "$DOCKER_VERSION" ] && ! $DOCKER; then
        warn "--docker-version was provided without --with-docker and will be ignored."
    fi
}

ubuntu_codename_from_version() {
    case "$1" in
        26.04) printf '%s\n' "resolute" ;;
        25.10) printf '%s\n' "questing" ;;
        25.04) printf '%s\n' "plucky" ;;
        24.10) printf '%s\n' "oracular" ;;
        24.04) printf '%s\n' "noble" ;;
        23.10) printf '%s\n' "mantic" ;;
        23.04) printf '%s\n' "lunar" ;;
        22.10) printf '%s\n' "kinetic" ;;
        22.04) printf '%s\n' "jammy" ;;
        21.10) printf '%s\n' "impish" ;;
        21.04) printf '%s\n' "hirsute" ;;
        20.10) printf '%s\n' "groovy" ;;
        20.04) printf '%s\n' "focal" ;;
        19.10) printf '%s\n' "eoan" ;;
        19.04) printf '%s\n' "disco" ;;
        18.10) printf '%s\n' "cosmic" ;;
        18.04) printf '%s\n' "bionic" ;;
        17.10) printf '%s\n' "artful" ;;
        17.04) printf '%s\n' "zesty" ;;
        16.10) printf '%s\n' "yakkety" ;;
        16.04) printf '%s\n' "xenial" ;;
        15.10) printf '%s\n' "wily" ;;
        15.04) printf '%s\n' "vivid" ;;
        14.10) printf '%s\n' "utopic" ;;
        14.04) printf '%s\n' "trusty" ;;
        13.10) printf '%s\n' "saucy" ;;
        13.04) printf '%s\n' "raring" ;;
        12.10) printf '%s\n' "quantal" ;;
        12.04) printf '%s\n' "precise" ;;
        11.10) printf '%s\n' "oneiric" ;;
        11.04) printf '%s\n' "natty" ;;
        10.10) printf '%s\n' "maverick" ;;
        10.04) printf '%s\n' "lucid" ;;
        9.10) printf '%s\n' "karmic" ;;
        9.04) printf '%s\n' "jaunty" ;;
        8.10) printf '%s\n' "intrepid" ;;
        8.04) printf '%s\n' "hardy" ;;
        7.10) printf '%s\n' "gutsy" ;;
        7.04) printf '%s\n' "feisty" ;;
        6.10) printf '%s\n' "edgy" ;;
        6.06) printf '%s\n' "dapper" ;;
        5.10) printf '%s\n' "breezy" ;;
        5.04) printf '%s\n' "hoary" ;;
        4.10) printf '%s\n' "warty" ;;
        *) return 1 ;;
    esac
}

detect_ubuntu_codename() {
    local codename=""
    local version_id=""

    if [ -n "$UBUNTU_CODENAME_OVERRIDE" ]; then
        printf '%s\n' "$UBUNTU_CODENAME_OVERRIDE"
        return 0
    fi

    if [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        codename="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
        version_id="${VERSION_ID:-}"
    fi

    if [ -z "$codename" ] && command -v lsb_release >/dev/null 2>&1; then
        codename="$(lsb_release -cs 2>/dev/null || true)"
    fi

    case "$codename" in
        n/a|N/A) codename="" ;;
    esac

    if [ -z "$codename" ] && [ -n "$version_id" ]; then
        codename="$(ubuntu_codename_from_version "$version_id" || true)"
    fi

    [ -n "$codename" ] || die "Could not detect Ubuntu codename. Re-run with --ubuntu-codename <codename>."
    printf '%s\n' "$codename"
}

ensure_ubuntu_like_system() {
    local distro_id=""
    local distro_like=""
    local pretty_name="this system"

    if [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        distro_id="${ID:-}"
        distro_like="${ID_LIKE:-}"
        pretty_name="${PRETTY_NAME:-this system}"
    fi

    if [ -z "$distro_id" ]; then
        warn "Could not identify the operating system from /etc/os-release."
        return 0
    fi

    case " $distro_id $distro_like " in
        *" ubuntu "*) ;;
        *)
            die "This installer targets Ubuntu. Detected: $pretty_name."
            ;;
    esac
}

detect_apt_architecture() {
    local arch
    arch="$(dpkg --print-architecture)"

    case "$arch" in
        amd64|arm64|armhf|s390x|ppc64el)
            printf '%s\n' "$arch"
            ;;
        *)
            die "Docker's Ubuntu repository does not provide packages for architecture: $arch"
            ;;
    esac
}

install_prerequisites() {
    local packages="ca-certificates curl gnupg"

    run_as_root rm -f /etc/apt/sources.list.d/docker.list /etc/apt/sources.list.d/docker.sources
    run_as_root apt-get update

    if apt-cache show apt-transport-https >/dev/null 2>&1; then
        packages="$packages apt-transport-https"
    fi

    run_as_root apt-get install -y $packages
}

install_standalone_prerequisites() {
    run_as_root apt-get update
    run_as_root apt-get install -y ca-certificates curl
}

check_repository_packages() {
    local codename="$1"
    local arch="$2"
    local packages_url="${DOCKER_REPO_URL}/dists/${codename}/${DOCKER_CHANNEL}/binary-${arch}/Packages.gz"

    if $SKIP_REPO_CHECK; then
        return 0
    fi

    info "Checking Docker repository for Ubuntu ${codename}/${arch}..."
    if ! curl -fsSL -o /dev/null "$packages_url"; then
        die "Docker packages were not found for Ubuntu codename '${codename}', architecture '${arch}', channel '${DOCKER_CHANNEL}'. Use --ubuntu-codename, --channel, or --skip-repo-check if you know this repository is valid."
    fi
}

remove_conflicting_packages() {
    local conflicts

    if ! $REMOVE_CONFLICTS; then
        return 0
    fi

    conflicts="$(dpkg --get-selections \
        docker.io \
        docker-compose \
        docker-compose-v2 \
        docker-doc \
        podman-docker \
        containerd \
        runc 2>/dev/null | awk '{print $1}' || true)"

    if [ -n "$conflicts" ]; then
        run_as_root apt-get remove -y $conflicts
    fi
}

configure_docker_repository() {
    local codename="$1"
    local arch="$2"
    local keyring="/etc/apt/keyrings/docker.gpg"
    local source_file="/etc/apt/sources.list.d/docker.list"
    local tmp_key

    tmp_key="$(mktemp)"
    curl -fsSL "${DOCKER_REPO_URL}/gpg" -o "$tmp_key"

    run_as_root install -m 0755 -d /etc/apt/keyrings
    run_as_root gpg --dearmor --yes -o "$keyring" "$tmp_key"
    run_as_root chmod a+r "$keyring"
    rm -f "$tmp_key"

    printf 'deb [arch=%s signed-by=%s] %s %s %s\n' \
        "$arch" "$keyring" "$DOCKER_REPO_URL" "$codename" "$DOCKER_CHANNEL" |
        run_as_root tee "$source_file" >/dev/null

    run_as_root apt-get update
}

install_docker_packages() {
    local packages=""

    if $DOCKER; then
        if [ -n "$DOCKER_VERSION" ]; then
            packages="$packages docker-ce=$DOCKER_VERSION docker-ce-cli=$DOCKER_VERSION"
        else
            packages="$packages docker-ce docker-ce-cli"
        fi

        packages="$packages containerd.io docker-buildx-plugin"
    elif $COMPOSE && [ "$COMPOSE_METHOD" != "standalone" ]; then
        packages="$packages docker-ce-cli"
    fi

    if $COMPOSE && [ "$COMPOSE_METHOD" != "standalone" ]; then
        packages="$packages docker-compose-plugin"
    fi

    if [ -n "$packages" ]; then
        run_as_root apt-get install -y $packages
    fi
}

start_docker_service() {
    if ! $DOCKER; then
        return 0
    fi

    if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files docker.service >/dev/null 2>&1; then
        if ! run_as_root systemctl enable --now docker >/dev/null 2>&1; then
            warn "Docker was installed, but the docker service could not be started with systemctl."
        fi
    elif command -v service >/dev/null 2>&1; then
        if ! run_as_root service docker start >/dev/null 2>&1; then
            warn "Docker was installed, but the docker service could not be started with service."
        fi
    else
        warn "Docker was installed, but no supported service manager was found to start it."
    fi
}

add_user_to_docker_group() {
    local target_user="${SUDO_USER:-${USER:-}}"

    if ! $DOCKER || ! $ADD_CURRENT_USER; then
        return 0
    fi

    if [ -z "$target_user" ] || [ "$target_user" = "root" ]; then
        warn "Skipping docker group membership because no non-root invoking user was detected."
        return 0
    fi

    if getent group docker >/dev/null 2>&1; then
        run_as_root usermod -aG docker "$target_user"
        warn "User '${target_user}' was added to the docker group. Log out and back in before running docker without sudo."
    else
        warn "Docker group was not found, so user '${target_user}' was not added."
    fi
}

latest_compose_version() {
    curl -fsSL https://api.github.com/repos/docker/compose/releases/latest |
        sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' |
        head -n 1
}

compose_binary_architecture() {
    local machine
    machine="$(uname -m)"

    case "$machine" in
        x86_64|amd64) printf '%s\n' "x86_64" ;;
        aarch64|arm64) printf '%s\n' "aarch64" ;;
        armv7l|armv7*) printf '%s\n' "armv7" ;;
        s390x) printf '%s\n' "s390x" ;;
        ppc64le|ppc64el) printf '%s\n' "ppc64le" ;;
        *) die "Standalone Docker Compose does not provide a known binary for machine: $machine" ;;
    esac
}

install_standalone_compose() {
    local version="$COMPOSE_VERSION"
    local arch
    local url
    local tmp_binary

    if [ -z "$version" ]; then
        version="$(latest_compose_version)"
    fi

    [ -n "$version" ] || die "Could not determine the latest Docker Compose version. Re-run with --compose-version <version>."

    arch="$(compose_binary_architecture)"
    url="https://github.com/docker/compose/releases/download/${version}/docker-compose-linux-${arch}"
    tmp_binary="$(mktemp)"

    curl -fL "$url" -o "$tmp_binary"
    run_as_root install -m 0755 "$tmp_binary" /usr/local/bin/docker-compose
    rm -f "$tmp_binary"
}

main() {
    local codename=""
    local arch=""
    local needs_docker_repo=false

    parse_args "$@"
    validate_args

    require_command apt-get
    require_command apt-cache
    require_command dpkg
    require_command awk
    require_command sed
    require_command head
    require_command mktemp
    require_command uname

    if [ "$(id -u)" -ne 0 ]; then
        require_command sudo
    fi

    ensure_ubuntu_like_system

    if $DOCKER || { $COMPOSE && [ "$COMPOSE_METHOD" != "standalone" ]; }; then
        needs_docker_repo=true
    fi

    if $needs_docker_repo; then
        codename="$(detect_ubuntu_codename)"
        arch="$(detect_apt_architecture)"

        install_prerequisites
        check_repository_packages "$codename" "$arch"
        remove_conflicting_packages
        configure_docker_repository "$codename" "$arch"
        install_docker_packages
        start_docker_service
        add_user_to_docker_group
    fi

    if $COMPOSE && [ "$COMPOSE_METHOD" = "standalone" ]; then
        install_standalone_prerequisites
    fi

    if $COMPOSE && [ "$COMPOSE_METHOD" != "plugin" ]; then
        require_command curl
        install_standalone_compose
    fi

    if $DOCKER; then
        info "Docker has been installed."
    fi

    if $COMPOSE; then
        case "$COMPOSE_METHOD" in
            plugin) info "Docker Compose plugin has been installed. Verify with: docker compose version" ;;
            standalone) info "Standalone Docker Compose has been installed. Verify with: docker-compose --version" ;;
            both) info "Docker Compose plugin and standalone docker-compose have been installed." ;;
        esac
    fi
}

main "$@"
