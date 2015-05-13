#!/bin/false

AUTOENV="$PWD"

D="$(mktemp -d ${TMPDIR:=/tmp}/autoenv-test-XXXXXX)"

clean_up()
{
    rm -Rf "$D"
}

trap clean_up INT TERM EXIT

cd "$D" || exit 5

export HOME="$D"

mkdir -p foo{,/{bar,baz}{,/{moo,meh}}}

. "$AUTOENV"/activate.sh
