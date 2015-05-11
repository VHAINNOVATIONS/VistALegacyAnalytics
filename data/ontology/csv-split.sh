#!/bin/bash
#

set -x
set -e

split -l 500 ICD9.csv
for f in x??; do echo $f; head -1 ICD9.csv > /tmp/$$; cat $f >> /tmp/$$; cp /tmp/$$ $f; done
zip -9r ICD9-csv.zip ???
rm x??

# end
