#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <file>"
  exit 1
fi

file=$1
if [ ! -f "$file" ]; then
  echo "File not found: $file"
  exit 1
fi

# Remove the file extension
file_no_ext=${file%.*}

# if multiple files specified, combine into one
cat $file_no_ext.asm > $file_no_ext.tmp

# add remaining args if specified
while [ -n "$2" ]; do
  file=$2
  if [ ! -f "$file" ]; then
    echo "File not found: $file"
    exit 1
  fi
  cat $file >> $file_no_ext.tmp
  shift
done

clang -E - -Wno-everything < $file_no_ext.tmp | sed 's/#.*//g' > $file_no_ext.tmp2

# assemble bin and create listing
nasm -f bin -o $file_no_ext.com $file_no_ext.tmp2 -l $file_no_ext.lst

# copy to .bin for ease of use with blinkenlights
cp $file_no_ext.com $file_no_ext.bin
rm $file_no_ext.tmp*
