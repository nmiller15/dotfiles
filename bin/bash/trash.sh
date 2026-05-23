#!/usr/bin/bash

FILE_PATH=$1
LAST_PART=$(basename $FILE_PATH)

mv $FILE_PATH ~/.Trash/$LAST_PART'
