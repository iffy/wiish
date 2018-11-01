#!/bin/sh
# Update the embedded helloworld starting template you get from `wiish init` with the helloworld example
set -e

src="examples/helloworld"
dst="src/wiishpkg/building/data/initapp"
cp ${src}/*.nim ${dst}/
cp ${src}/wiish.toml ${dst}/
