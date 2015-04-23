#!/bin/bash --norc

AUTOENV="$PWD"

D="$(mktemp -d ${TMPDIR:=/tmp}/autoenv-test-XXXXXX)"

clean_up()
{
    rm -Rf "$D"
}

trap clean_up INT TERM EXIT

cd "$D" || exit 5

export HOME="$D"

. "$AUTOENV"/activate.sh

touch ~/.autoenv_authorized

mkdir -p foo{,/{bar,baz}{,/{moo,meh}}}

for n in foo{,/{bar,baz}{,/{moo,meh}}}/.env-{enter,leave}; do
    echo "echo $n >> '$D'/what" > "$n"
    autoenv_authorize_env "$PWD/$n"
done

cd foo/bar/moo

echo "-X-" >> "$D"/what
cd ../../baz/meh
echo "-Y-" >> "$D"/what
cd "$D"

diff -Naur - what <<EOF
foo/.env-enter
foo/bar/.env-enter
foo/bar/moo/.env-enter
-X-
foo/bar/moo/.env-leave
foo/bar/.env-leave
foo/baz/.env-enter
foo/baz/meh/.env-enter
-Y-
foo/baz/meh/.env-leave
foo/baz/.env-leave
foo/.env-leave
EOF
