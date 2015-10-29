#!/bin/bash
# Taken from the X Strike Force Build System

set -e

debDir="$(pwd)/debian"

if [ ! -d "$debDir/repack/prune" ]; then
	exit 0
fi

if [ '--upstream-version' != "$1" ]; then
	exit 1
fi

version="$2"
filename="$3"

if [ -z "$version" ] || [ ! -f "$filename" ]; then
	exit 1
fi

dir="$(dirname "$filename")"
filename="$(basename "$filename")"
dir="$(readlink -f "$dir")"
tempdir="$(mktemp -d)"

cd "$tempdir"
tar xf "$dir/$filename"
cat "$debDir"/repack/prune/* | while read file; do
	if [ -e */"$file" ]; then
		echo "Pruning $file"
		rm -rf */"$file"
	fi
done

dfsgfilename="$filename"
if [[ "$dfsgfilename" != *[~+]ds* ]]; then
	pkg="$(dpkg-parsechangelog -l"$debDir/changelog" -SSource)"
	ver="$(dpkg-parsechangelog -l"$debDir/changelog" -SVersion)"
	origVer="${ver%-*}" # strip everything from the last dash
	origVer="$(echo "$origVer" | sed -r 's/^[0-9]+://')" # strip epoch
	upstreamVer="${origVer%%[+~]ds*}"
	dfsgBits="${origVer#$upstreamVer}"
	
	dfsgfilename="${dfsgfilename/.orig/$dfsgBits.orig}"
fi
tar -czf "$dir/$dfsgfilename" *
cd "$dir"
rm -rf "$tempdir"
echo "Done pruning upstream tarball into $dfsgfilename"

exit 0
