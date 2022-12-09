#!/bin/sh

cd $(dirname "$0")/..

VERSION=$(grep --color=never -Po "^version: \K.*" pubspec.yaml || true)
echo "-$VERSION-"

mkdir release
rm release/* -rf

# echo "build for Android"
# flutter build apk
# cp build/app/outputs/flutter-apk/app-release.apk release/task-launcher-$VERSION.apk


echo "build for Windows"
flutter build windows

echo "copy release files"
mkdir release/task-launcher-win-$VERSION
cp build/windows/runner/Release/* release/task-launcher-win-$VERSION/ -r
cp README.md release/task-launcher-win-$VERSION/
cp ReleaseNotes.md release/task-launcher-win-$VERSION/
cp setup.json release/task-launcher-win-$VERSION/setup-sample.json
cp scripts/data/run.sh release/task-launcher-win-$VERSION/
cp scripts/data/run.bat release/task-launcher-win-$VERSION/


echo "zip release files"
cd release
rm task-launcher-win-$VERSION/data/flutter_assets/assets/cert/* -rf
powershell Compress-Archive task-launcher-win-$VERSION task-launcher-win-$VERSION.zip
# tar -a -c -f task-launcher-win-$VERSION.zip task-launcher-win-$VERSION
# rm task-launcher-win-$VERSION -rf

