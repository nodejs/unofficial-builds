# Node.js unofficial-builds project

**<https://unofficial-builds.nodejs.org/>**

_**This project is experimental: its output is not guaranteed to remain consistent and its existence is not guaranteed into the future.** This project is in need of a community of maintainers to keep it viable. If you would like to join, please submit pull requests to improve the work here._

The **unofficial-builds** project aims to provide Node.js binaries for some platforms not made available officially by the Node.js project at nodejs.org. Node.js is used on a large variety of platforms, but the Node.js project, in consultation with the [Node.js Build Working Group](https://github.com/nodejs/build), maintains a limited set of platforms that it tests code on and produces binaries for.

This list of officially supported platforms is available in the Node.js [BUILDING.md](https://github.com/nodejs/node/blob/master/BUILDING.md#platform-list), where you can also find details in the [official nodejs.org binaries](https://github.com/nodejs/node/blob/master/BUILDING.md#official-binary-platforms-and-toolchains) section. Some platforms are "supported" in that they are tested by the Node.js test infrastructure, but they don't have binaries produced for nodejs.org. Other platforms receive minimal or no official support.

**unofficial-builds** attempts to provide basic Node.js binaries for some platforms that either not supported or only partially supported by Node.js. This project **does not provide any guarantees** and its results are not rigorously tested. Builds made available at nodejs.org have very high quality standards for code quality, support on the relevant platforms and for timing and methods of delivery. Builds made available by unofficial-builds have minimal or no testing; the platforms may have no inclusion in the official Node.js test infrastructure. These builds are made available for the convenience of their user community but those communities are expected to assist in their maintenance.

## Builds

 * **linux-x64-musl**: Linux x64 binaries compiled against [musl libc](https://www.musl-libc.org/) version 1.1.20. Primarily useful for users of Alpine Linux 3.9 and later. Linux x64 with musl is considered "Experimental" by Node.js but the Node.js test infrastructure includes some Alpine test servers so support is generally good. These Node.js builds require the `libstdc++` package to be installed on Alpine Linux, which is not installed by default. You can add this by running `apk add libstdc++`.
* **linux-x64-glibc-217**: Linux x64, compiled with glibc 2.17 to support [older Linux distros](https://en.wikipedia.org/wiki/Glibc#Version_history), QNAP QTS 4.x and 5.x, and Synology DSM 7, and other environments where a newer glibc is unavailable.
* **linux-arm64-glibc-217**: Linux arm64, compiled with glibc 2.17 to support [older Linux distros](https://en.wikipedia.org/wiki/Glibc#Version_history), QNAP QTS 4.x and 5.x, and Synology DSM 7, and other environments where a newer glibc is unavailable.
 * **linux-x86**: Linux x86 (32-bit) binaries compiled against libc 2.17, similar to the way the official [linux-x64 binaries are produced](https://github.com/nodejs/node/blob/master/BUILDING.md#official-binary-platforms-and-toolchains). 32-bit Linux binaries were dropped for Node.js 10 and 32-bit support is now considered "Experimental".
 * **linux-armv6l**: Linux ARMv6 binaries, cross-compiled on Ubuntu 16.04 with a [custom GCC 6 toolchain](https://github.com/rvagg/rpi-newer-crosstools) (for Node.js versions earlier than 16) or Ubuntu 18.04 with a [custom GCC 8 toolchain](https://github.com/rvagg/rpi-newer-crosstools) (for Node.js 16 and later) in a similar manner to the official linux-armv7l binaries. Binaries are optimized for `armv6zk` which is suitable for Raspberry Pi devices (1, 1+ and Zero in particular). ARMv6 binaries were dropped from Node.js 12 and ARMv6 support is now considered "Experimental".
 * **riscv64**: Linux riscv64 (RISC-V), cross compiled on Ubuntu 20.04 with the toolchain which the Adoptium project uses (for  now...). Built with --openssl-no-asm (Should be with --with-intl=none but that gets overriden)

"Experimental" status for Node.js is defined as:
> Experimental: May not compile or test suite may not pass. The core team does not create releases for these platforms. Test failures on experimental platforms do not block releases. Contributions to improve support for these platforms are welcome.

Therefore, it is possible that unofficial-builds may occasionally fail to produce binaries and fixes to support these platforms may need to be contributed to Node.js.

## How

This project makes use of a server provided by the Node.js Build Working Group to compile and host binaries. Currently all binaries are produced on that server within specialized Docker containers. The possibility of future expansion to platforms that require alternative infrastructure to build is not excluded.

The server is configured according to the Ansible [unofficial-builds](https://github.com/nodejs/build/tree/master/ansible/roles/unofficial-builds) role in the [nodejs/build](https://github.com/nodejs/build) repository. This is executed via the [create-unofficial-builds.yml](https://github.com/nodejs/build/blob/master/ansible/playbooks/create-unofficial-builds.yml) playbook.

The build process operates as the `nodejs` user and in `/home/nodejs` which has the following layout:

 - `bin/` - currently only contains [`deploy-unofficial-builds.sh`](https://github.com/nodejs/build/tree/master/ansible/roles/unofficial-builds/files/deploy-unofficial-builds.sh) which is responsible for updating `unofficial-builds/` with this repository when it's updated (see below).
 - `download/` - the directory served at <https://unofficial-builds.nodejs.org/download/>
 - `logs/` - the directory served at <https://unofficial-builds.nodejs.org/logs/> and containing logs for deploys of this repository [github-webhook.log](http://unofficial-builds.nodejs.org/logs/github-webhook.log) and a directory for each build, identified by a datetime string combined with the Node.js version string of the compiled version. These log directories contain a master `build.log` and a log file for each compile build "recipe" which is the output of the Docker container for that build.
 - `staging/` - a directory where build assets are placed by the Docker containers prior to promotion to `download/` along with a SHASUMS256.txt file and updated index.json and index.tab files.
 - `unofficial-builds/` - a clone of this repository, updated automatically when `master` is updated here.
 - `var/` - where state files are stored for the build queue, build locking and release checking.

The build process can be described as:

1. This repository is cloned onto the unofficial-builds server whenever it is updated (triggered via [github-webhook](https://github.com/rvagg/github-webhook)) and Docker images contained within the [`/recipes`](/recipes) directory are built by means of the [`/bin/deploy.sh`](/bin/deploy.sh) script which in turn calls the [`/bin/prepare-images.sh`](/bin/prepare-images.sh) script.
2. A periodic service runs every 5 minutes via systemd on the server which calls [`/bin/periodic.sh`](/bin/periodic.sh) script.
3. `periodic.sh` calls [`/bin/check-releases.sh`](/bin/check-releases.sh) for each release line being checked ("release", "rc", etc.). Any new versions that check-releases.sh finds are added to the build queue via [`/bin/queue-push.sh`](/bin/queue-push.sh) (the build queue uses a locking mechanism to prevent concurrent changes).
4. `periodic.sh` calls [`/bin/build-if-queued.sh`](/bin/build-if-queued.sh) which will execute a build if there is at least one build in the queue and no builds are currently running. [`/bin/queue-pop.sh`](/bin/queue-pop.sh) is used to atomically remove the next build from the queue. Note that only zero or one build per periodic run is executed. If the queue has more than one build, these will be deferred until later periodic runs.
5. When `build-if-queued.sh` encounters a build in the queue that it can execute, it calls [`/bin/build.sh`](/bin/build.sh) to perform the build. This script iterates through the images that have been pre-built from the [`/recipes`](/recipes) directory, starting with the [`/recipes/fetch-source`](/recipes/fetch-source) recipe that fetches the source file for the given version and validates official releases using GPG keys. Optionally, a recipe might have a `should-build` file which is used to determine if the recipe should run for a specific Node.js version. Each recipe is passed this source and is given a staging directory to place its binaries in. After all recipes are finished, builds are promoted to the <https://unofficial-builds.nodejs.org/download/> directory along with a SHASUMS256.txt file and the index.tab and index.json files for that release type are updated.

## Manual build triggers

Admins with access to the server can manually trigger a build using the [`/bin/queue-push.sh`](/bin/queue-push.sh) command. e.g.

```sh
su nodejs # perform the action as the "nodejs" user so as to retain proper queue permissions
cd ~
unofficial-builds/bin/queue-push.sh v16.4.0 # queue a new build for "v16.4.0" - the "v" is necessary
```

This places "v16.4.0" into `~/var/build_queue` which will be read on the next invocation of the build check timer. It may take up to 5 minutes for the build to start, at which point the log should be visible at <https://unofficial-builds.nodejs.org/logs/>.

The same process can be used to queue `rc` or `test` builds.

## Team

unofficial-builds is maintained by:

* [@rvagg](https://github.com/rvagg)
* [@richardlau](https://github.com/richardlau)
* [@sxa](https://github.com/sxa)
* ... _contribute something and add yourself here!_

## Emeritus

* [@mmarchini](https://github.com/mmarchini)
