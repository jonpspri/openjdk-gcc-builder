FROM ubuntu:18.04

ARG GCC_PREFIX_DIR=/usr/gcc
ARG GCC_SRC_DIR=/gcc/src
ARG GCC_BUILD_DIR=/gcc/build
ARG GCC_VERSION=8.2.0
ARG GLIBC_COMPAT_DIR=/usr/glibc-compat

SHELL [ "bash", "-o", "pipefail", "-c" ]

RUN apt-get -q update \
	&& DEBIAN_FRONTEND=noninteractive apt-get -qy --no-install-recommends install \
		build-essential \
		ca-certificates \
		libmpc-dev \
		wget \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
COPY shasums.txt .

RUN	wget -nv "https://ftpmirror.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.gz" \
	&& grep -F "$GCC_VERSION" shasums.txt | sha256sum -c \
	&& mkdir -p "$GCC_SRC_DIR" "$GCC_BUILD_DIR" \
	&& tar zfx gcc-$GCC_VERSION.tar.gz  -C "$GCC_SRC_DIR" --strip 1 \
	&& rm gcc-$GCC_VERSION.tar.gz

#
#  BUILD GCC
#
#  Until somethings starts failing regression tests, run with the
#  --no-bootstrap option to reduce compile time and space
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

# This is specific to OpenJDK -- extract the libraries actually used
RUN mkdir -p "$GLIBC_COMPAT_DIR" \
	&& find "$GCC_PREFIX_DIR/lib64" \
		\( -name 'libstdc++*' -o -name 'libgcc*' \) -type f -print0 \
	| xargs -I{} -0 cp -v {} "$GLIBC_COMPAT_DIR/"
