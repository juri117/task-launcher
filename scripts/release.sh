#!/bin/sh

cd $(dirname "$0")/..

APP_NAME="task-launcher"
VERSION=$(grep --color=never -Po "^version: \K.*" pubspec.yaml || true)

case $(uname | tr '[:upper:]' '[:lower:]') in
    linux*)
    PLATFORM="linux"
    RELEASE_PATH="build/linux/x64/release/bundle"
    ZIP_CMD=7z
    ;;
    mingw64*)
    PLATFORM=windows
    RELEASE_PATH="build/windows/x64/runner/Release"
    ZIP_CMD="C:/Program Files/7-Zip/7z.exe"
    7z --help
    ;;
    *)
    echo "unsupported OS"
    exit 1
    ;;
esac

RELEASE_FOLDER="$APP_NAME-$VERSION-$PLATFORM"

echo "$APP_NAME-$VERSION"
echo "$RELEASE_FOLDER"

mkdir release
rm release/* -rf


echo "build for $PLATFORM"
flutter build $PLATFORM --release

echo "copy release files"
mkdir release/$RELEASE_FOLDER
cp $RELEASE_PATH/* release/$RELEASE_FOLDER/ -r
cp README.md release/$RELEASE_FOLDER/
cp ReleaseNotes.md release/$RELEASE_FOLDER/
cp config.json release/$RELEASE_FOLDER/config-sample.json
cp scripts/data/run.sh release/$RELEASE_FOLDER/
cp scripts/data/run.bat release/$RELEASE_FOLDER/
cp icon.png release/$RELEASE_FOLDER/

echo "$VERSION" >> release/$RELEASE_FOLDER/version.txt

echo "zip release files"
cd release

"$ZIP_CMD" a -r $RELEASE_FOLDER.zip $RELEASE_FOLDER

echo "DONE"
