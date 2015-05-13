#!/bin/bash --norc

for n in tests/*test.sh ; do
    echo -n $n
    bash --norc $n && echo " ok" || echo " KO"
done
