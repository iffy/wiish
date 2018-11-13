#!/bin/sh
# Update the embedded starting template you get from `wiish init`
set -e

src="examples/sdl2"
dst="src/wiishpkg/building/data/initapp"
rm -r "${dst}" && mkdir -p "${dst}"
cp ${src}/*.nim ${dst}/
cp ${src}/wiish.toml ${dst}/
cp -R ${src}/resources ${dst}/resources/
