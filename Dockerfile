## Definite image args
ARG image_registry
ARG image_name=astra
ARG image_version=1.7.5-slim

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                         Base image                          #
#             First stage, install base components            #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
FROM ${image_registry}${image_name}:${image_version}

SHELL ["/bin/bash", "-exo", "pipefail", "-c"]

## Def initial arg(will be replaced with docker build opt)
ARG version=1.0.0

## Build args
ENV \
    VERSION="${version}" \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TERM=linux \
    TZ=Etc/UTC \
## https://devcenter.heroku.com/articles/tuning-glibc-memory-behavior
    MALLOC_ARENA_MAX=2 \
    TERM=xterm-256color

## Install build deps
# python3, python3-pip: required for various build scripts and gyp (Google's Python-based build tool)
# g++, gcc, make: base compilers and build tools
# git: to fetch submodules and version info
# curl: for downloading dependencies and testing
# netbase: for network-related tests
# procps: provides basic process management tools (used in tests)
# ninja-build: faster alternative to make for compiling
# ca-certificates: for HTTPS and SSL certificate verification
# pkg-config: helps locate installed libraries and their compile flags
# libssl-dev: OpenSSL support for TLS/SSL in Node.js
# zlib1g-dev: for compression support (zlib)
# libicu-dev: for internationalization support (Intl module)
# lsb-release: used to detect Linux distribution version
# gnupg2: for verifying GPG signatures during setup
# xz-utils: for handling .xz compressed files
# libc6-dev: for standard C library headers and development files
# gdb: for debugging Node.js and native addons
# lcov: for test coverage analysis
# valgrind: for memory debugging and profiling
# tzdata: for timezone data support
# locales: for locale support in Intl and other modules
# libnss3-dev: for network security services (NSS) support
# libcurl4-openssl-dev: for libcurl with OpenSSL support
# libv8-dev: V8 engine development headers (Node.js runtime)
# libhttp-parser-dev: for HTTP parsing (used by Node.js core)
# libc-ares-dev: for asynchronous DNS resolution
# libnghttp2-dev: for HTTP/2 support
# libbrotli-dev: for Brotli compression support
# libzstd-dev: for Zstandard compression support
# libuv1-dev: libuv library (asynchronous I/O core of Node.js)
# libxml2-dev, libxslt1-dev: for XML/XSLT processing in native addons
# libjemalloc-dev: alternative memory allocator (optional)
# libsnappy-dev: for Snappy compression support
# libsqlite3-dev: for SQLite support in native modules
# libgtest-dev: for running C++ unit tests
# icu-devtools: development tools for ICU (used with libicu-dev)
# python3-distutils: required for some Python-based build tools
# ncurses-bin: for terminal handling (used in REPL and tests)
# inotify-tools: for filesystem change monitoring (used in fs.watch tests)
# python2: for Astra 1.7.x - required for configure
RUN --mount=type=bind,source=./scripts,target=/usr/local/sbin,readonly \
    apt-install.sh \
        python3 \
        python3-pip \
        g++ \
        gcc \
        make \
        git \
        curl \
        netbase \
        procps \
        ninja-build \
        ca-certificates \
        pkg-config \
        libssl-dev \
        zlib1g-dev \
        libicu-dev \
        lsb-release \
        gnupg2 \
        xz-utils \
        libc6-dev \
        gdb \
        lcov \
        valgrind \
        tzdata \
        locales \
        libnss3-dev \
        libcurl4-openssl-dev \
        libv8-dev \
        libhttp-parser-dev \
        libc-ares-dev \
        libnghttp2-dev \
        libbrotli-dev \
        libzstd-dev \
        libuv1-dev \
        libxml2-dev \
        libxslt1-dev \
        libjemalloc-dev \
        libsnappy-dev \
        libsqlite3-dev \
        libgtest-dev \
        icu-devtools \
        python3-distutils \
        ncurses-bin \
        inotify-tools \
        python-is-python3 \
## Try to install python2.7 for astra 1.7.x
    && maybe-install-python2.sh \
## Remove unwanted binaries
    && rm-binary.sh \
        addgroup \
        adduser \
        delgroup \
        deluser \
        passwd \
        su \
        update-passwd \
        useradd \
        userdel \
        usermod \
## Remove cache
    && apt-clean.sh \
## Prune unused files
    && { \
        find /run/ -mindepth 1 -ls -delete || :; \
    } \
    && install -d -m 01777 /run/lock \
## Deduplication cleanup
    && dedup-clean.sh /usr/ \
## Def version container
    && echo "Build NodeJs container version ${VERSION}" >> /etc/issue \
## Get image package dump
    && mkdir -p /usr/share/rocks \
    && ( \
        echo "# os-release" && cat /etc/os-release \
        && echo "# dpkg-query" \
        && dpkg-query -f \
            '${db:Status-Abbrev},${binary:Package},${Version},${source:Package},${Source:Version}\n' \
            -W \
        ) >/usr/share/rocks/dpkg.query \
## Check can be preview /etc/issue
    && { \
        grep -qF 'cat /etc/issue' /etc/bash.bashrc \
        || echo 'cat /etc/issue' >> /etc/bash.bashrc; \
    }

WORKDIR /build

CMD [ "bash" ]
