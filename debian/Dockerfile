FROM tianon/debian-devel

RUN echo 'deb http://incoming.debian.org/debian-buildd buildd-unstable main contrib non-free' > /etc/apt/sources.list.d/incoming.list

# start by adding just "debian/control" so we can get mk-build-deps with maximum caching
COPY control /usr/src/docker.io/debian/
WORKDIR /usr/src/docker.io

# get all the build deps of _this_ package in a nice repeatable way
RUN apt-get update && mk-build-deps -irt'apt-get --no-install-recommends -yV' debian/control && dpkg-checkbuilddeps

# need our debian/ directory to compile _this_ package
COPY . /usr/src/docker.io/debian

# go download and unpack our upstream source
RUN uscan --force-download --verbose --download-current-version
RUN DOCKER_TARBALLS=.. ./debian/helpers/download-libcontainer
RUN /tianon/extract-origtargz.sh

# tianon is _really_ lazy, and likes a preseeded bash history
RUN echo '/tianon/extract-origtargz.sh && dpkg-buildpackage -us -uc && lintian -EvIL+pedantic' >> /root/.bash_history
