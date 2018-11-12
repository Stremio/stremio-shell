# Building Stremio package inside Docker container

First make sure you have Docker installed on your system and your user is member of the docker group.

In `distros` directory there are OS specific docker files and scripts to automatically build the package. These files are used by the `build-package.sh` utility, located in the `dist-utils` directory.

For a list of the supported distros, you can peek at the `distros` directory or just run `./dist-utils/build-package.sh` without any arguments.

To build a package, you have to run the `build-package.sh` with first argument - the distro name and second, optional, argument - the output path.

Only **x86_64** architecture is supported.

Here's an example of how to build a Fedora rpm package in `/tmp/stremio-fedora` directory.

```
[stremio-shell]$ mkdir -p /tmp/stremio-fedora
[stremio-shell]$ ./dist-utils/build-package.sh Fedora /tmp/stremio-fedora
[stremio-shell]$ ls /tmp/stremio-fedora/
stremio-4.4.10-1.fc29.x86_64.rpm
```

If you don't want to use Docker, check out the `disttros/your-distro/` directory. This is usefull if your machine is not x86_64 architecture for example.

For every distro there are at least three files there:

<dl>
 <dt><code>Dockerfile</code></dt>
 <dd>This is the Docker configuration file. It is very useful even if you're not using Docker. Here are described all the tools and files you need to build the Stremio package.</dd>
 <dt><code>mkconfig.sh</code></dt>
 <dd>This script generates the needed configuration files for the latter build.</dd>
 <dt><code>package.sh</code></dt>
 <dd>This script compiles the Stremio application and builds the installation package.</dd>
 </dl>

So the local build process is as follows:
1. Go to the directory of your distro.
2. Install all the required tools and libraries described in the `Dockerfile`. Bare in mind that if you are using unsupported architecture or for some other reasons, the library names may differ. It's your responsibility to figure it out and install the correct ones.
3. Run the `./mkconfig.sh` to set up the build configuration.
4. Run the `./package.sh` script and wait for the build process to finish.

Here's an example for ArchLinux:

```
[stremio-shell]$ cd distros/ArchLinux/
[ArchLinux]$ grep pacman Dockerfile 
RUN pacman -Syu --noconfirm
RUN pacman -S --needed --noconfirm sudo git wget librsvg
[ArchLinux]$ sudo pacman -S sudo git wget librsvg
 * * *
[ArchLinux]$ ./mkconfig.sh
[ArchLinux]$ ./package.sh
 * * *
[ArchLinux]$ ls *.pkg*
stremio-git-4.4.10.r47.5277756-1-x86_64.pkg.tar
```

As you can see, if there are no errors during the build process, we get our installation package in the current directory. It's ready to install. Give it a try:

```
[ArchLinux]$ sudo pacman -U stremio-git-4.4.10.r47.5277756-1-x86_64.pkg.tar
```

Now you can run it either from the shell or from your preferred desktop environment.

If you've created a build scripts for any other distro, don't hesitate to submit a pull request. 