#!/bin/bash
. ./build-qt5-env
THREADS=-j30
NEW_QTDIR=/usr/local/Trolltech/Qt5/Qt-5.0.0-$QT_WEEKLY_REV
QT5_MODULES="qtjsbackend qtxmlpatterns qtscript qtquick1 qtdeclarative qt3d qtsensors qtlocation"

rm -rf $NEW_QTDIR
cd qt5
git checkout master
git clean -dxf
git reset --hard HEAD
git submodule foreach "git checkout master"
git submodule foreach "git clean -dxf"
git submodule foreach "git reset --hard HEAD"
git fetch || exit 1
git reset --hard $WEEKLY_QT5_HASH || exit 1
./init-repository --module-subset=qtbase,`echo $QT5_MODULES | tr " " ","` -f || exit 1
git submodule foreach "git fetch" || exit 1
git submodule update --recursive || exit 1
echo ==========================================================
git submodule status
echo ==========================================================

export QTDIR=$NEW_QTDIR
export PATH=$QTDIR/bin:$PATH

./configure -opensource -confirm-license -no-pch -nomake examples -nomake demos -nomake tests -no-gtkstyle -nomake translations -qt-zlib -qt-libpng -qt-libjpeg -qt-sql-sqlite -release -prefix $QTDIR

cd qtbase && make $THREADS && make install && cd ..
if [ $? -ne 0 ] ; then
  echo FAIL: building qtbase
  exit 1
fi

for module in $QT5_MODULES
do
  cd $module && qmake && make $THREADS && make install && cd ..
  if [ $? -ne 0 ] ; then
    echo FAIL: building $module.
    exit 1
  fi
done

echo
echo Build Completed.
