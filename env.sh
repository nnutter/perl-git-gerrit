#!/usr/bin/env bash

set -o pipefail
set -o nounset

OWD="$(pwd)"

cd "$(git rev-parse --show-cdup)"

git submodule update --init
git submodule foreach 'git checkout master'
git submodule foreach 'git pull --ff-only'

for D in $(git submodule foreach --quiet pwd); do
    if [ -d "$D/lib" ]; then
        PERL5LIB="$D/lib:$PERL5LIB"
    fi
done
PERL5LIB="$(pwd)/lib:$PERL5LIB"
export PERL5LIB

export PATH="$(pwd)/bin:$PATH"

cd "$OWD"

set +o nounset
