FROM ubuntu:18.04
MAINTAINER Jonathan Springer <jonpspri@gmail.com>

#
#  Maybe these shouldn't be arguments, but I'm leaving them here
#  for documentation and potential customization purposes.  Also
#  at some point I may want to provide the Tarballs via a volume
#  mount rather than a download.
#
ARG TARBALL_DIR=/tarballs

ARG GCC_PREFIX_DIR=/usr/gcc
ARG GCC_SRC_DIR=/gcc/src
ARG GCC_BUILD_DIR=/gcc/build

SHELL [ "bash", "-o", "pipefail", "-c" ]

RUN apt-get -q update \
	&& DEBIAN_FRONTEND=noninteractive apt-get -qy install \
		build-essential \
		libmpc-dev \
		wget

RUN mkdir -p $TARBALL_DIR $GCC_SRC_DIR
WORKDIR $TARBALL_DIR
COPY shasums.txt .

#
#  These args are down here so Docker doesn't have to redo the Ubuntu apt
#  gets whenever it's compiling a different version combination
#
ARG GCC_VERSION=8.2.0

#
#  If the files exist, don't download them again (volume mount), otherwise
#  check them against the SHA sums that are expected.
#
#  I don't know how to get docker to persist things on an internal volume if
#  I don't declare one for the build, so I am going to pass on that for now.
#
RUN test -f gcc-$GCC_VERSION.tar.gz || \
			wget -nv "https://ftpmirror.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.gz"

RUN fgrep "$GCC_VERSION" shasums.txt | sha256sum -c \
	&& tar zfx gcc-$GCC_VERSION.tar.gz  -C "$GCC_SRC_DIR" --strip 1

WORKDIR $GCC_BUILD_DIR
RUN "$GCC_SRC_DIR/configure" \
 			--disable-multilib \
      --prefix="$GCC_PREFIX_DIR" \
      --libdir="$GCC_PREFIX_DIR/lib" \
      --libexecdir="$GCC_PREFIX_DIR/lib"
RUN make -j$(grep -c '^processor' /proc/cpuinfo)  all
RUN make -j$(grep -c '^processor' /proc/cpuinfo)  install
RUN cd $GCC_SRC_DIR && cp COPYING*.LIB $GCC_PREFIX_DIR

ARG TARGET_TARBALL=/openjdk-gcc-libs-$GCC_VERSION.tar.gz
RUN cd $GCC_PREFIX_DIR && tar --hard-dereference -zcf "$TARGET_TARBALL" .
