#!/bin/bash

WEBKIT_BUILD_DIR="WebKitBuild/Release"

rm -rf $WEBKIT_BUILD_DIR/thin
mkdir $WEBKIT_BUILD_DIR/thin

cp -r $WEBKIT_BUILD_DIR/bin $WEBKIT_BUILD_DIR/thin
cp -r $WEBKIT_BUILD_DIR/lib $WEBKIT_BUILD_DIR/thin
cp -r $WEBKIT_BUILD_DIR/imports $WEBKIT_BUILD_DIR/thin

QT_DIR="/mnt/store/ARM/Qt5/Qt-5.0.0-ARM/"
cp -r $QT_DIR/lib $WEBKIT_BUILD_DIR/thin
cp -r $QT_DIR/imports $WEBKIT_BUILD_DIR/thin
cp -r $QT_DIR/plugins $WEBKIT_BUILD_DIR/thin

REV=`svn info |grep Revision: |cut -c11-`


cd $WEBKIT_BUILD_DIR/thin
zip -y -r ../../../${REV}.zip .
