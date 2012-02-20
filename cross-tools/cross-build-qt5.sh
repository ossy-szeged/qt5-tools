#!/bin/bash

QTDIR_PATH="/mnt/store/ARM/Qt5"

d=`diff qt5-tools/build-qt5-env $QTDIR_PATH/newest_version 2>&1 | wc -l`
if [ "$d" = "0" ]
then
  echo "The newest working version is already installed."
  exit 0
fi


. qt5-tools/build-qt5-env
NEW_QTDIR="$QTDIR_PATH/Qt-5.0.0-$QT_WEEKLY_REV"
QT5_MODULES="qtjsbackend qtxmlpatterns qtscript qtdeclarative qtquick1 qt3d qtsensors qtlocation"

export QTDIR=$NEW_QTDIR
export PATH=$QTDIR/bin:$PATH
export PATH=/mnt/store/ARM/toolchain/softfp/arm-none-linux-gnueabi-4.4.6/bin:$PATH


rm -rf qt5
git clone https://git.gitorious.org/qt/qt5.git || exit 1


cd qt5

git submodule foreach "git clean -dxf" || exit 1

git submodule foreach "git checkout master" || exit 1
git submodule foreach "git reset --hard head" || exit 1
git fetch || exit 1
git reset --hard $WEEKLY_QT5_HASH || exit 1
./init-repository --module-subset=qtbase,`echo $QT5_MODULES | tr " " ","` -f || exit 1
git submodule foreach "git fetch" || exit 1
git submodule update --recursive || exit 1
echo ==========================================================
git submodule status
echo ==========================================================


cp ../qt5-tools/cross-tools/qmake.conf qtbase/mkspecs/linux-arm-gnueabi-g++/
git apply ../qt5-tools/cross-tools/qtjsbackend.patch --directory=qtjsbackend


./configure -arch arm -xplatform linux-arm-gnueabi-g++ -opensource -confirm-license -no-pch -nomake examples -nomake demos -nomake tests -no-gtkstyle -nomake translations -qt-zlib -qt-libpng -qt-libjpeg -qt-sql-sqlite -release -prefix $QTDIR -v


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


cp ../qt5-tools/build-qt5-env $QTDIR_PATH/newest_version
unlink $QTDIR_PATH/Qt-5.0.0-ARM
ln -sf $NEW_QTDIR $QTDIR_PATH/Qt-5.0.0-ARM

echo
echo Build Completed.
