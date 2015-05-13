#!/bin/bash --norc

. tests/common.sh

for n in foo{,/{bar,baz}{,/{moo,meh}}}/.env-{enter,leave}; do
    echo "echo $n >> '$D'/what" > "$n"
done

cd foo > $HOME/out <<EOF
y
EOF

if [[ "$PWD" != "$HOME/foo" ]]; then echo "cd foo fail" ; fi
grep WARNING $HOME/out >&/dev/null || echo "cd foo auth fail"

# ---

cd $HOME > $HOME/out <<EOF
y
EOF

if [[ "$PWD" != "$HOME" ]]; then echo "cd home fail" ; fi
grep WARNING $HOME/out >&/dev/null || echo "cd home auth fail"

# ---

cd foo > $HOME/out <<EOF
y
EOF

if [[ "$PWD" != "$HOME/foo" ]]; then echo "cd foo fail" ; fi
grep WARNING $HOME/out >&/dev/null && echo "cd foo auth fail"

# ---

cd $HOME > $HOME/out <<EOF
y
EOF

if [[ "$PWD" != "$HOME" ]]; then echo "cd home fail" ; fi
grep WARNING $HOME/out >&/dev/null && echo "cd home auth fail"

# ---

autoenv_deauthorize_env "$PWD/.env-enter"

