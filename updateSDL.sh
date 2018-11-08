#!/bin/bash
# This script gets the latest SDL XCode project and places it where it needs to be within the wiish source
SDL_NAME="SDL2-2.0.9"
TARNAME="${SDL_NAME}.tar.gz"
FETCH_URL="https://www.libsdl.org/release/${TARNAME}"
DST="src/wiishpkg/building/data/sdl2src"

mkdir -p tmp
pushd tmp

if ! [ -e "$SDL_NAME" ]; then
    if ! [ -e "$TARNAME" ]; then
        echo "Downloading from $FETCH_URL"
        curl "$FETCH_URL" -o "$TARNAME"
    fi
    echo "Unpacking..."
    tar xf "$TARNAME"
fi
popd

[ -e "${DST}" ] && rm -r "${DST}"
cp -R "tmp/$SDL_NAME" "$DST"

# remove unneeded files
rm -r "${DST}/test"
rm -r "${DST}/docs"
