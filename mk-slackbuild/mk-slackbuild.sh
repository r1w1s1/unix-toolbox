#!/bin/sh
#
# mk-slackbuild.sh
#
# Generate a conservative SlackBuild skeleton.
# This is a starting point, not a finished SlackBuild.
#
# Copyright 2026 r1w1s1
# All rights reserved.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
#  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
#  EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# mk-slackbuild.sh
#
# Generate a conservative SlackBuild skeleton.
# This is a starting point, not a finished SlackBuild.

set -e

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
  echo "Usage: $0 <prgnam> [version]"
  exit 1
fi

PRGNAM=$1
VERSION=${2:-UNKNOWN}
DIR=$PRGNAM

if [ -e $DIR ]; then
  echo "Directory $DIR already exists"
  exit 1
fi

mkdir $DIR
cd $DIR

# ------------------------------------------------------------
# SlackBuild
# ------------------------------------------------------------

cat > $PRGNAM.SlackBuild << EOF
#!/bin/bash
#
# Slackware build script for $PRGNAM
#
# Copyright 2026 r1w1s1
# All rights reserved.
#
# Redistribution and use of this script, with or without modification, is
# permitted provided that the following conditions are met:
#
# 1. Redistributions of this script must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
#  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
#  EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

cd \$(dirname \$0) ; CWD=\$(pwd)

PRGNAM=$PRGNAM
VERSION=\${VERSION:-$VERSION}
BUILD=\${BUILD:-1}
TAG=\${TAG:-_SBo}
ARCH=\${ARCH:-}
PKGTYPE=\${PKGTYPE:-tgz}

if [ -z "\$ARCH" ]; then
  case \$(uname -m) in
    i?86) ARCH=i586 ;;
    arm*) ARCH=arm ;;
       *) ARCH=\$(uname -m) ;;
  esac
fi

if [ "\$ARCH" = i586 ]; then
  SLKCFLAGS="-O2 -march=i586 -mtune=i686"
  LIBDIRSUFFIX=""
elif [ "\$ARCH" = i686 ]; then
  SLKCFLAGS="-O2 -march=i686 -mtune=i686"
  LIBDIRSUFFIX=""
elif [ "\$ARCH" = x86_64 ]; then
  SLKCFLAGS="-O2 -fPIC"
  LIBDIRSUFFIX="64"
else
  SLKCFLAGS="-O2"
  LIBDIRSUFFIX=""
fi

if [ -n "\$PRINT_PACKAGE_NAME" ]; then
  echo \$PRGNAM-\$VERSION-\$ARCH-\$BUILD\$TAG.\$PKGTYPE
  exit 0
fi

TMP=\${TMP:-/tmp/SBo}
PKG=\$TMP/package-\$PRGNAM
OUTPUT=\${OUTPUT:-/tmp}

set -e

rm -rf \$PKG
mkdir -p \$TMP \$PKG \$OUTPUT

cd \$TMP
rm -rf \$PRGNAM-\$VERSION

if ! ls \$CWD/\$PRGNAM-\$VERSION.tar.?z* >/dev/null 2>&1; then
  echo "Source archive for \$PRGNAM-\$VERSION not found."
  exit 1
fi

tar xvf \$CWD/\$PRGNAM-\$VERSION.tar.?z*
cd \$PRGNAM-\$VERSION

chown -R root:root .

# ------------------------------------------------------------------
# BUILD SYSTEM:
# Uncomment ONE section and remove the others.
# ------------------------------------------------------------------

# === AUTOTOOLS ===
# CFLAGS="\$SLKCFLAGS" \\
# ./configure \\
#   --prefix=/usr \\
#   --libdir=/usr/lib\${LIBDIRSUFFIX} \\
#   --sysconfdir=/etc \\
#   --localstatedir=/var
#
# make
# make install DESTDIR=\$PKG

# === CMAKE ===
# mkdir build
# cd build
# cmake \\
#   -DCMAKE_C_FLAGS="\$SLKCFLAGS" \\
#   -DCMAKE_CXX_FLAGS="\$SLKCFLAGS" \\
#   -DCMAKE_INSTALL_PREFIX=/usr \\
#   -DCMAKE_INSTALL_LIBDIR=lib\${LIBDIRSUFFIX} \\
#   -DCMAKE_BUILD_TYPE=Release \\
#   ..
#
# make
# make install DESTDIR=\$PKG
# cd ..

# === MESON ===
# mkdir meson-build
# cd meson-build
# meson setup \\
#   --prefix=/usr \\
#   --libdir=lib\${LIBDIRSUFFIX} \\
#   --sysconfdir=/etc \\
#   --localstatedir=/var \\
#   --buildtype=release \\
#   ..
#
# ninja
# DESTDIR=\$PKG ninja install
# cd ..

find \$PKG -print0 | xargs -0 file | grep ELF | cut -f1 -d: | \\
  xargs strip --strip-unneeded 2>/dev/null || true

for mandir in \$PKG/usr/man \$PKG/usr/share/man; do
  if [ -d "\$mandir" ]; then
    ( cd "\$mandir"
      find . -type f -exec gzip -9 {} \\;
      for i in \$(find . -type l); do
        ln -s "\$(readlink "\$i").gz" "\$i.gz"
        rm "\$i"
      done
    )
  fi
done

mkdir -p \$PKG/usr/doc/\$PRGNAM-\$VERSION
cp -a COPYING* NEWS* README* TODO* \\
  \$PKG/usr/doc/\$PRGNAM-\$VERSION 2>/dev/null || true

cat \$CWD/\$PRGNAM.SlackBuild > \$PKG/usr/doc/\$PRGNAM-\$VERSION/\$PRGNAM.SlackBuild

mkdir -p \$PKG/install
cp \$CWD/slack-desc \$PKG/install/slack-desc

cd \$PKG
/sbin/makepkg -l y -c n \$OUTPUT/\$PRGNAM-\$VERSION-\$ARCH-\$BUILD\$TAG.\$PKGTYPE
EOF

chmod +x $PRGNAM.SlackBuild

# ------------------------------------------------------------
# .info (quoted values – REQUIRED)
# ------------------------------------------------------------

cat > $PRGNAM.info << EOF
PRGNAM="$PRGNAM"
VERSION="$VERSION"
HOMEPAGE=""
DOWNLOAD=""
MD5SUM=""
DOWNLOAD_x86_64=""
MD5SUM_x86_64=""
REQUIRES=""
MAINTAINER="r1w1s1"
EMAIL="r1w1s1@fastmail.com"
EOF

# ------------------------------------------------------------
# slack-desc
# ------------------------------------------------------------

cat > slack-desc << EOF
# HOW TO EDIT THIS FILE:
# The "handy ruler" below makes it easier to edit a package description.  Line
# up the first '|' above the ':' following the base package name, and the '|' on
# the right side marks the last column you can put a character in.  You must make
# exactly 11 lines for the formatting to be correct.  It's also customary to
# leave one space after the ':'.

         |-----handy-ruler------------------------------------------------------|
$PRGNAM: $PRGNAM (short description)
$PRGNAM:
$PRGNAM: One or two lines describing what the software does.
$PRGNAM:
$PRGNAM:
$PRGNAM:
$PRGNAM:
$PRGNAM: Homepage:
$PRGNAM:
$PRGNAM:
$PRGNAM:
EOF

# ------------------------------------------------------------
# README
# ------------------------------------------------------------

cat > README << EOF
$PRGNAM

Brief description of the software.

This SlackBuild was generated as a starting point and must be reviewed
and adjusted before use or submission.
EOF

echo "SlackBuild skeleton created in ./$DIR"

