#!/usr/bin/env bash
set -e

if test -z "$PATHTOGCC"; then
  PATHTOGCC=g++
fi

for INDEX in $SOURCE_INDEXES
do
  CFLAGS=$(eval echo "\$COMPILER_OPTIONS_$INDEX")
  SRCFILE=$(eval echo "\$SOURCE_FILE_$INDEX")
  OBJFILE=$(eval echo "\$OBJECT_FILE_$INDEX")
  $PATHTOGCC -std=gnu++11 -c $CFLAGS $SRCFILE -o $OBJFILE
done

$PATHTOGCC $OBJECT_FILES $LINKER_OPTIONS -o $EXECUTABLE_FILE
