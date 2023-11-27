#!/bin/bash
FILE_CONTENT="PBCL2-666 [fix]"
REGEX="[4][0-9]{5}73(?:[0-9]{8})|[5][0-9]{5}73(?:[0-9]{8})|[3][0-9]{5}74(?:[0-9]{8})|[4][0-9]{5}74(?:[0-9]{8})|[5][0-9]{5}74(?:[0-9]{8})|[4][0-9]{5}95(?:[0-9]{8})|[5][0-9]{5}95(?:[0-9]{8})|[4][0-9]{5}97(?:[0-9]{8})|[5][0-9]{5}97(?:[0-9]{8})"
if [[ $FILE_CONTENT =~ $REGEX ]]; then
 echo "Nice commit!"
else
  echo "Bad commit \"$FILE_CONTENT\", check format."
 echo $ERROR_MSG
 exit 1
fi