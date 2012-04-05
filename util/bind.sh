#!/bin/sh
#
# Copyright (C) 2009-2012 by Internet Systems Consortium, Inc. ("ISC")
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND ISC DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS.  IN NO EVENT SHALL ISC BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
# OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.

# $Id: bind.sh,v 1.25 2012/04/05 22:16:47 sar Exp $

# Get the bind distribution for the libraries
# This script is used to build the DHCP distribution and shouldn't be shipped
#
# Usage: sh bind.sh <DHCP branch or version> <git bind direcotry>
#
# By default we will do a git clone of bind into the default bind directory
# and then get the proper bind tarball from that.  As getting a git clone
# may be slow for people working remotely we also allow them to indicate
# a directory that already holds the clone in which case we use it instead.
# We expect the kit.sh script to create the temporary directory $binddir
# and to do a git pull to get the latest code.

topdir=`pwd`
binddir=$topdir/bind
gitbinddir=$topdir/bindgit

case $# in 
    2) 
	gitbinddir=$2
	;;
    1) 
	;;
    *) echo "usage: sh bind.sh [<branch>|<version>] [git binddir]" >&2
       exit 1
       ;;
esac

case "$1" in 
###
### Robie calls this script with the building branch name so we can
### build with BIND9 HEAD for the relevant branch we would release
### with.
###
### XXX: We can't use the 'snapshot' syntax right now because kit.sh
### pulls the version.tmp off the branch name, and then stores a
### tarball with vastly different values.  So the version.tmp can not
### be used to chdir down into the directory that is unpacked.
###
v4_2) noSNAP=snapshot BINDTAG=v9_8; BRANCHTAG=v9_8 ;;
HEAD|v[0-9]_[0-9].*) noSNAP=snapshot BINDTAG=HEAD; BRANCHTAG=v9_9 ;;
###
### For ease of use, this records the sticky tag of versions
### released with each point release.
###
4.2.3-P1|4.2.3-P2) BINDTAG=v9_8_1_P1; BRANCHTAG=v9_8 ;;
4.2.3rc1|4.2.3) BINDTAG=v9_8_1; BRANCHTAG=v9_8 ;;
4.2.2rc1|4.2.2) BINDTAG=v9_8_0_P4; BRANCHTAG=v9_8 ;;
4.2.1|4.2.1-P1|4.2.2b1) BINDTAG=v9_8_0; BRANCHTAG=v9_8 ;;
4.2.1rc1) BINDTAG=v9_8_0rc1; BRANCHTAG=v9_8 ;;
4.2.1b1) BINDTAG=v9_8_0b1; BRANCHTAG=v9_8 ;;
4.2.0rc1|4.2.0) BINDTAG=v9_7_1; BRANCHTAG=v9_7 ;;
4.2.0b2) BINDTAG=v9_7_1rc1; BRANCHTAG=v9_7 ;;
4.2.0b1) BINDTAG=v9_7_0_P1; BRANCHTAG=v9_7 ;;
4.2.0a2|4.2.0a1) BINDTAG=v9_7_0b3; BRANCHTAG=v9_7 ;;
*) echo "bind.sh: unsupported version: $1" >&2
   exit 1
   ;;
esac

# Delete all previous bind stuff
rm -rf bind

# If needed clone the directory, note that
# kit.sh does a pull so we don't have to
# kit.sh will also build the binddir if it doesn't
# exist
if !(test -d ${gitbinddir}) ; then
    echo Cloning Bind into ${gitbinddir}
    git clone repo.isc.org:/proj/git/prod/bind9.git ${gitbinddir}
fi

# We seem to need the checkout to get to the correct branch
# especially for tags of the form v9_8
echo Checking out verison $BRANCHTAG
pushd $gitbinddir
git checkout $BRANCHTAG
popd

# Create the bind tarball, which has the side effect of
# setting up the bind directory we will use for building
# the export libraries
echo Creating tarball for $BINDTAG
sh $gitbinddir/util/kit.sh $SNAP $gitbinddir $BINDTAG $binddir

# and copy the bind makeifle to it
cp util/Makefile.bind bind/Makefile

cd $binddir
. ./version.tmp

version=${MAJORVER}.${MINORVER}.${PATCHVER}${RELEASETYPE}${RELEASEVER}
bindsrcdir=bind-$version
mm=${MAJORVER}.${MINORVER}

# move the tar file to a known place for use by the make dist command
echo Moving tar file to bind.tar.gz for distribution
mv bind-${mm}*.tar.gz bind.tar.gz

