#!/bin/bash
set -e

debDir="$PWD/debian"

if [ ! -d "$debDir/repack/prune" ]; then
	exit 0
fi

if [ '--upstream-version' != "$1" ]; then
	echo >&2 "unexpected argument '$1' (expected '--upstream-version')"
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
	echo >&2 "warning: no 'DFSG' bits in version '$debVer' (~ds1 or similar), not pruning"
	exit 0
fi

dir="$(dirname "$filename")"
filename="$(basename "$filename")"
dir="$(cd "$dir" && pwd -P)"

dfsgFilename="$filename"
case "$dfsgFilename" in
	*${dfsgBits}*) ;; # if our filename already has appropriate "dfsg bits", continue as-is
	*) dfsgFilename="${dfsgFilename/.orig/$dfsgBits.orig}" ;;
esac
targetTar="$dir/$dfsgFilename"

# quick, rough sanity check
! grep -qE '^/|^\.\./' "$debDir"/repack/prune/* "$debDir"/repack/keep/* 2>/dev/null

IFS=$'\n'
prune=( $(grep -vE '^#|^$' "$debDir"/repack/prune/*) ) || true
unset IFS

IFS=$'\n'
keep=( $(grep -vE '^#|^$' "$debDir"/repack/keep/* 2>/dev/null) ) || true
unset IFS

tempDir="$(mktemp -d -t docker-orig-repack-XXXXXXXXXX)"
trap "rm -rf '$tempDir'" EXIT

mkdir -p "$tempDir/orig"
tar -xf "$dir/$filename" -C "$tempDir/orig" --strip-components=1

mkdir -p "$tempDir/repack"
( cd "$tempDir/orig" && cp -al . "$tempDir/repack" )

( cd "$tempDir/repack" && rm -rf "${prune[@]}" )

for k in "${keep[@]}"; do
	[ -d "$tempDir/orig/$k" ] || continue
	[ ! -d "$tempDir/repack/$k" ] || continue
	mkdir -p "$tempDir/repack/$k"
	( cd "$tempDir/orig/$k" && cp -al . "$tempDir/repack/$k" )
done

rm -rf "$tempDir/orig"

subfolderName="${dfsgFilename%.tar.*}"
mv "$tempDir/repack" "$tempDir/$subfolderName"

tar -czf "$targetTar" -C "$tempDir" "$subfolderName"

# trap will clean up tempDir

echo "Done pruning upstream tarball into $dfsgFilename"
exit 0
