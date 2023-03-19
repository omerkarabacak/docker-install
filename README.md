# Docker and Docker-compose Installer Script for Ubuntu

This is a Bash script for installing Docker and Docker-compose on Ubuntu. The script is compatible with Ubuntu 18.04, 20.04, and 22.04, and supports optional installation of both Docker and Docker-compose.

## Prerequisites

Before running the script, make sure that you have a clean Ubuntu installation and that you have administrative privileges on the system.

## Usage

To use the script, follow these steps:

1. Download the script to your system.
2. Make the script executable by running the following command in the directory where the script is located:

```
chmod +x docker-install.sh
```

3. Run the script with the appropriate command line arguments to install Docker and/or Docker-compose, as described below.

### Command Line Arguments

The script supports the following command line arguments:

- `--with-docker`: Installs Docker.
- `--with-compose`: Installs Docker-compose.

You can use these arguments to customize the installation according to your needs.

### Installing Docker and Docker-compose

To install both Docker and Docker-compose, run the following command:

```
./docker-install.sh --with-docker --with-compose
```


This command installs Docker and adds the current user to the `docker` group, enabling the user to run Docker commands without sudo. It also installs Docker-compose and verifies that both Docker and Docker-compose are installed correctly.

### Installing Docker-compose Only

To install Docker-compose only, run the following command:

```
./docker-install.sh --with-compose
```


This command installs Docker-compose and verifies that it is installed correctly.

### Installing Docker Only

To install Docker only, run the following command:

```
./docker-install.sh --with-docker
```

This command installs Docker and adds the current user to the `docker` group, enabling the user to run Docker commands without sudo. It also verifies that Docker is installed correctly.

### Verification

After installing Docker and/or Docker-compose, you can verify that the installation was successful by running the following commands:

- `docker --version`: Prints the version of Docker installed on your system.
- `docker-compose --version`: Prints the version of Docker-compose installed on your system (if installed).

## License

This script is licensed under the MIT License. See the `LICENSE` file for details.

## Disclaimer

This script is provided as-is and without any warranty. Use at your own risk. The author is not responsible for any damage or loss caused by the use of this script.
