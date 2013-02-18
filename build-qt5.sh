#!/bin/bash

N_THREADS=30
BUILD_TYPE="-release"
DEVELOPER_BUILD=
MIRROR_URL=

function usage() {
    echo "Usage: $0 [-d] [-D] [-j #NUMBER] [-m URL]"
    echo "       -d     : builds with debug symbols."
    echo "       -D     : builds in developer mode (do not install anything)."
    echo "       -j #   : builds with # threads (default is $N_THREADS)."
    echo "       -m URL : uses URL (without trailing slash!) as mirror to the git related tasks. (default is git://gitorious.org)"
}

while getopts "h?dDj:m:" opt; do
    case $opt in
        h|\?)
            usage
            exit 0
            ;;
        d)
            echo "[$0] Building with debug symbols."
            BUILD_TYPE="-debug"
            ;;
        D)
            echo "[$0] Developer build enabled."
            DEVELOPER_BUILD=1
            ;;
        j)
            echo "[$0] Building with $OPTARG threads."
            N_THREADS=$OPTARG
            ;;
        m)
            echo "[$0] Using mirror $OPTARG to clone Qt5."
            MIRROR_URL=$OPTARG
            ;;
    esac
done

RELDIR=`dirname $0`
ABSDIR=`cd $RELDIR;pwd`

. $ABSDIR/build-qt5-env

THREADS=
if [ $N_THREADS -gt 1 ]; then
    THREADS=-j$N_THREADS
fi

MIRROR=
if [ $MIRROR_URL ]; then
    MIRROR="--mirror $MIRROR_URL"
else
    MIRROR_URL="git://gitorious.org"
fi

NEW_QTDIR=
INSTALL_TYPE=
if [ $DEVELOPER_BUILD ]; then
    NEW_QTDIR=$ABSDIR/qtsdk/qtbase
    INSTALL_TYPE=-developer-build
else
    NEW_QTDIR=/usr/local/Trolltech/Qt5/$QT_WEEKLY_REV
    INSTALL_TYPE="-prefix $NEW_QTDIR"
    rm -rf $NEW_QTDIR
fi

if [ ! -d qtsdk ]; then
    git clone -b master $MIRROR_URL"/qtsdk/qtsdk.git" qtsdk
fi

for module in $NON_QT5_MODULES
do
  if [ ! -d qtsdk/$module ]; then
    module_branch="${module}_BRANCH"
    git clone -b ${!module_branch} $MIRROR_URL"/qt/"$module".git" qtsdk/$module
  fi
done


cd qtsdk
git checkout stable
git clean -dxf
git reset --hard HEAD
git submodule foreach "git checkout stable"
git submodule foreach "git clean -dxf"
git submodule foreach "git reset --hard HEAD"
git fetch || exit 1
git reset --hard $WEEKLY_QT5_HASH || exit 1
./init-repository $MIRROR/ --module-subset=qtbase,`echo $QT5_MODULES | tr " " ","` -f || exit 1
git submodule foreach "git fetch" || exit 1
git submodule update --recursive || exit 1
echo ==========================================================
git submodule status
echo ==========================================================

for module in $NON_QT5_MODULES
do
  module_hash="${module}_HASH"
  module_branch="${module}_BRANCH"
  cd $module && git checkout ${!module_branch} && git clean -dxf && git reset --hard HEAD && git fetch && git checkout ${!module_hash} && cd ..
  if [ $? -ne 0 ] ; then
    echo FAIL: updating $module
    exit 1
  fi
done

export QTDIR=$NEW_QTDIR
export PATH=$QTDIR/bin:$PATH

./configure -opensource -confirm-license -no-pch -nomake examples -nomake demos -nomake tests -no-gtkstyle -nomake translations -qt-zlib -qt-sql-sqlite $BUILD_TYPE $INSTALL_TYPE

cd qtbase && make $THREADS && if [ ! $DEVELOPER_BUILD ]; then make install; fi && cd ..
if [ $? -ne 0 ] ; then
  echo FAIL: building qtbase
  exit 1
fi

for module in $QT5_MODULES $NON_QT5_MODULES
do
  cd $module && qmake && make $THREADS && if [ ! $DEVELOPER_BUILD ]; then make install; fi && cd ..
  if [ $? -ne 0 ] ; then
    echo FAIL: building $module.
    exit 1
  fi
done

echo
echo Build Completed.
