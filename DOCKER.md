# Building Stremio package inside Docker container

First make sure you have Docker installed on your system and your user is member of the docker group.

In this directory there are OS specific docker files and scripts to automatically build the package.

For Arch Linux use **./build_arch.sh**. This script makes use of **ArchLinux.dockerfile** to build the Arch Linux package.

For Ubuntu use **./build_deb.sh**. This script makes use of **Ubuntu.dockerfile** to build the Ubuntu package

If you don't want to use Docker, check out the contents of the Docker file for your OS and run the commands locally.
Note that on some OSes the build commands must be run as unprivileged user. You can skip the user creation steps.