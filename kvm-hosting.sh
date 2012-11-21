#!/bin/sh
set -e +u

if [ "$1" = -d ]; then
    interpreter=cat
    shift
else
    interpreter=sh
fi

if [ "$#" -gt 3 ]; then
    echo 'Too many parameters' >&2
    exit 1
fi

xsltproc --stringparam service "$2" --stringparam name "$3" kvm-hosting.xsl "$1" | $interpreter
