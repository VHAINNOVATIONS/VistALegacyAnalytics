#!/bin/bash
#
# sample bash script for running RecordLoader
#
# Copyright (c)2005-2007 Mark Logic Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# The use of the Apache License does not indicate that this project is
# affiliated with the Apache Software Foundation.
#

function readlink() {
  DIR=$(echo "${1%/*}")
  (cd "$DIR" && echo "$(pwd -P)")
}

# look for GNU readlink first (OS X, BSD, Solaris)
READLINK=`type -P greadlink`
if [ -z "$READLINK" ]; then
    # if readlink is not GNU-style, setting BASE will fail
    READLINK=`type -P readlink`
fi
BASE=`$READLINK -f $0 2>/dev/null`
if [ -z "$BASE" ]; then
    # try the bash function
    BASE=$(readlink $0)
else
    BASE=`dirname $BASE`
fi
if [ -z "$BASE" ]; then
    echo Error initializing environment from $READLINK
    $READLINK --help
    exit 1
fi

CPSEPARATOR=':'
# Check for cygwin.
# The uname -o option does not work on some platforms, but that isn't a problem.
UNAMESTR=`uname -o 2>/dev/null`
if [ "$UNAMESTR" = "Cygwin" ]; then
   CPSEPARATOR=';'
   BASE=`cygpath -wp $BASE`
fi

echo BASE=$BASE

CP=$BASE/xcc.jar
CP=$CP$CPSEPARATOR$BASE/xpp3-1.1.4c.jar
CP=$CP$CPSEPARATOR$BASE/recordloader.jar

FILES=
VMARGS=-Xincgc
# OS X defaults to MacRoman
VMARGS=$VMARGS" -Dfile.encoding=UTF-8"

for a in $*; do
    if [ -e "$a" ]; then
        FILES="$FILES $a"
    else
        VMARGS="$VMARGS $a"
    fi
done

if [ -d "$JAVA_HOME" ]; then
  JAVA=$JAVA_HOME/bin/java
else
  JAVA=java
fi

$JAVA -cp $CP $VMARGS com.marklogic.ps.RecordLoader $FILES

# end xqsync.sh
