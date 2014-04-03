#!/bin/bash

### Function definitions START

# enable xtrace
set -x

function usage {
    echo "usage: catf -s <device-sid> -m <module1,module2,module3,...>"
}

function p {
local n=`date +"%Y-%m-%d %H:%M:%S %:z"`
echo \$n \$*
}
# accept parameter: package name
function run_test {
local mod=\$1
local cmd="\${adb_cmd} shell am instrument -w -e notAnnotation com.seven.asimov.it.annotation.Ignore -e package \${mod} com.seven.asimov.it/com.seven.asimov.it.IntegrationTestRunnerGa"

p "Start to test"
p \${cmd}
`\${cmd}`

local date_id=`date +%Y%m%d_%H%M%S`
cmd="\${adb_cmd} pull /sdcard/OCIntegrationTestsResults ./OCIntegrationTestsResults_\${mod}_\${date_id}"

p "Start to archive test result"
p \${cmd}
`\${cmd}`
}

### Function definitions END

############################################################3##################

# global variables
device_sid=""
module_id=""

while getopts :s:m: opt
do
    case \$opt in
    s)
    device_sid=\$OPTARG
    ;;

    m)
    module_id=\$OPTARG
    ;;

    *) ;;
    esac
done

if [ X\${device_sid} != X ]
then
    adb_cmd="adb -s \${device_sid} "
    p "Device serial id is: \${device_sid}"
else
    adb_cmd="adb "

    device_num=`adb devices | grep 'device' | wc -l`
    if [ \${device_num} -gt 2 ]
    then
        p "There are more than one device connected, please specify the device sid!"
        usage
        exit 1
    fi
fi

if [ X\${module_id} != X ]
then
    modules=`echo \${module_id} | tr ',' ' '`
    p "CATF module: \${modules}"
else
    p "module id cannot be empty!"
    usage
    exit 1
fi

for m in \${modules}
do
    run_test \$m
done

