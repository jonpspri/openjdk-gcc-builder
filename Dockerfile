FROM ubuntu:18.04

#
#  These are more parameters for documentation purposes and are unlikely
#  to be changed from the command line.
#
ARG GCC_PREFIX_DIR=/usr/gcc
ARG GCC_SRC_DIR=/builder/src
ARG GCC_BUILD_DIR=/builder/build
ARG GLIBC_COMPAT_DIR=/usr/glibc-compat

#
#  This is likely to be changed, though one should try to match the tag
#  to the argument.  To wit:
#
#    GCC_VERSION=8.2.0 docker build --build-arg GCC_VERSION=$GCC_VERSION \
#        --tag openjdk-gcc-build:$GCC_VERSION
#
ARG GCC_VERSION=8.2.0

#
#  Don't mess with this.  We use pipelines in the RUN steps and we want failures
#  to propagate outward to the &&s
#
SHELL [ "bash", "-o", "pipefail", "-c" ]

#
#  'build-essentials' may be overkill, but not by much.  Maybe someone in a
#  good mood will care to experiment.
#
RUN apt-get -q update \
	&& DEBIAN_FRONTEND=noninteractive apt-get -qy --no-install-recommends install \
		build-essential \
		ca-certificates \
		libmpc-dev \
		wget \
	&& rm -rf /var/lib/apt/lists/*

#
#  Download GCC, check to make sure the server wasn't hacked, and unpack
#  it into the source directory.
#
WORKDIR /tmp
COPY shasums.txt .
RUN	wget -nv "https://ftpmirror.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.gz" \
	&& grep -F "$GCC_VERSION" shasums.txt | sha256sum -c \
	&& mkdir -p "$GCC_SRC_DIR" "$GCC_BUILD_DIR" \
	&& tar zfx "gcc-$GCC_VERSION.tar.gz"  -C "$GCC_SRC_DIR" --strip 1 \
	&& rm "gcc-$GCC_VERSION.tar.gz"

#
#  BUILD GCC
#
#  Until somethings starts failing regression tests, run with the
#  --no-bootstrap option to reduce compile time and space
#
#  Copy licensing information into the install directory.
#
WORKDIR $GCC_BUILD_DIR
RUN "$GCC_SRC_DIR/configure" \
			--disable-bootstrap \
 			--disable-multilib \
      --prefix="$GCC_PREFIX_DIR" \
      --libdir="$GCC_PREFIX_DIR/lib" \
      --libexecdir="$GCC_PREFIX_DIR/lib"
RUN make -j"$(grep -c '^processor' /proc/cpuinfo)"  all \
 	&& make -j"$(grep -c '^processor' /proc/cpuinfo)" install \
 	&& cp "$GCC_SRC_DIR"/COPYING*.LIB "$GCC_PREFIX_DIR" \
	&& rm -rf ./*

#
#  This is specific to OpenJDK -- extract the two libraries actually used.
#  Don't both with symlinks because `ldconfig` will reconstruct them on the
#  other end.
#
RUN mkdir -p "$GLIBC_COMPAT_DIR" \
	&& find "$GCC_PREFIX_DIR/lib64" \
		\( -name 'libstdc++*' -o -name 'libgcc*' \) -type f -print0 \
	| xargs -I{} -0 cp -v {} "$GLIBC_COMPAT_DIR/"
