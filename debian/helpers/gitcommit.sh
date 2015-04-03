#!/bin/bash
set -e

uVersion="$1"
dVersion="$2"

if [ -z "$uVersion" ]; then
	uVersion="$(cat VERSION)"
fi
if [ -z "$dVersion" ]; then
	dVersion="$(dpkg-parsechangelog --show-field Version)"
fi

if [ "${uVersion%-dev}" = "$uVersion" ]; then
	# this is a straight-up release!  easy-peasy
	exec awk -F ': ' '$1 == "'"$uVersion"'" { print $2 }' debian/upstream-version-gitcommits
fi

# must be a nightly, so let's look for clues about what the git commit is

if git rev-parse &> /dev/null; then
	# well, this will be easy ;)
	exec git rev-parse --short HEAD
fi

if [ "${dVersion#*+*+}" != "$dVersion" ]; then
	# must be something like "1.1.2+10013+8c38a3d-1~utopic1" (nightly!)
	commit="${dVersion#*+*+}"
	commit="${commit%%-*}"
	exec echo "$commit"
fi

# unknown...
echo >&2 'warning: unable to determine DOCKER_GITCOMMIT'
