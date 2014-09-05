#!/bin/bash
# Taken from the X Strike Force Build System

set -e

if ! [ -d debian/repack/prune ]; then
	exit 0
fi

if [ "x$1" != x--upstream-version ]; then
	exit 1
fi

version="$2"
filename="$3"

if [ -z "$version" ] || ! [ -f "$filename" ]; then
	exit 1
fi

dir="$(pwd)"
tempdir="$(mktemp -d)"

cd "$tempdir"
tar xf "$dir/$filename"
cat "$dir"/debian/repack/prune/* | while read file; do
	if [ -e */"$file" ]; then
		echo "Pruning $file"
		rm -rf */"$file"
	fi
done

dfsgfilename="$filename"
if [[ "$dfsgfilename" != *dfsg* ]]; then
	dfsgfilename="${dfsgfilename/.orig/~dfsg1.orig}"
fi
tar -czf ${dir}/${dfsgfilename} *
cd "$dir"
rm -rf "$tempdir"
echo "Done pruning upstream tarball into $dfsgfilename"

exit 0
