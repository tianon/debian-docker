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

debVer="$(dpkg-parsechangelog -l"$debDir/changelog" -SVersion)"
origVer="${debVer%-*}" # strip everything from the last dash
origVer="$(echo "$origVer" | sed -r 's/^[0-9]+://')" # strip epoch
upstreamVer="${origVer%%[+~]ds*}"
dfsgBits="${origVer#$upstreamVer}"

if [ -z "$dfsgBits" ]; then
	echo "No 'DFSG' bits in '$debVer' (~ds1 or similar), not pruning"
	exit 0
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

dfsgFilename="$filename"
if [[ "$dfsgFilename" != *[~+]ds* ]]; then
	dfsgFilename="${dfsgFilename/.orig/$dfsgBits.orig}"
fi
tar -czf "$dir/$dfsgFilename" *
cd "$dir"
rm -rf "$tempdir"

echo "Done pruning upstream tarball into $dfsgFilename"
exit 0
