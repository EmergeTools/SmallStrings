#!/bin/bash

set -ex

NEW_HASHES_FILE=`mktemp`
shasum $1/*.lproj/Localizable.strings $1/localization/* | sort > $NEW_HASHES_FILE
retVal=0
cmp $NEW_HASHES_FILE $2 2> /dev/null || retVal=$? # The || prevents set -e from exiting early
if [ $retVal -ne 0 ]; then
    # If this process is killed halfway through, make sure that there's not an old hashes file lying around that could mislead
    rm $2 2> /dev/null || true
    ruby localize.rb $1
fi

PLACEHOLDER="\"placeholder1234\" = \"foo\"; // This is just a placeholder so that Apple knows that this language still has a localization"
for FILE in $1/*.lproj/Localizable.strings; do echo $PLACEHOLDER > $FILE; done

mv $NEW_HASHES_FILE $2
