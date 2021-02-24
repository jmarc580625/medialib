#!/bin/bash
EXEC_HOME=${0%/*}
source ${EXEC_HOME}/lib/coreLib.sh
[[ -z ${ensureLib+x} ]] && source ${EXEC_HOME}/lib/ensureLib.sh

echo before
ensure "(( 2 > 3 ))"
echo after
