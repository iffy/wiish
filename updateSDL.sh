#!/bin/bash
# This script puts the latest SDL2 and SDL2_ttf code into this project

function getit() {
    mkdir -p tmp
    pushd tmp
    
    NAME="$1"
    TARNAME="${NAME}.tar.gz"
    FETCH_URL="$2/${TARNAME}"
    DST="src/wiishpkg/building/data/$3"

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
    cp -R "tmp/$NAME" "$DST"

    # remove unneeded files
    rm -r "${DST}/test"
    rm -r "${DST}/docs"
}

## SDL2
getit "SDL2-2.0.9" "https://www.libsdl.org/release/" "SDL"

## SDL2_ttf
getit "SDL2_ttf-2.0.14" "https://www.libsdl.org/projects/SDL_ttf/release/" "SDL_TTF"

