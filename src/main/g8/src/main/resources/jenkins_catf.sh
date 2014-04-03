#!/usr/bin/env bash
cat > catf.sh <<'EOF'
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


EOF

### execute the scripts
chmod u+x catf.sh

## collect device and modules info
## assign module to specific devices (round-robin)
devices=(`adb devices | grep device | grep -v List | awk '{print \$1}' | tr '\n' ' '`)
modules=(`echo \$packages | tr ',' ' '`)

dev_len=\${#devices[@]}
mod_len=\${#modules[@]}

per_dev=()

if [ \$mod_len -gt \$dev_len ]; then
    step=\$dev_len
else
    step=\$mod_len
fi

for (( i=0; i<\$mod_len; i+=\$step ))
do
    for (( j=0; j<\$step; j++ ))
    do
        idx=\$[ \$i + \$j ]
        m="\${modules[\$idx]} \${per_dev[\$j]}"

        per_dev[\$j]=\$m
    done
done

### start catf.sh
for (( i=0; i<\${#per_dev[@]}; i++ ))
do
    echo "./catf.sh -s \${devices[\$i]} -m `echo \${per_dev[\$i]} | tr ' ' ','` 2>&1 > \${devices[\$i]}.log &"
    ./catf.sh -s \${devices[\$i]} -m `echo \${per_dev[\$i]} | tr ' ' ','` 2>&1 > \${devices[\$i]}.log &
done

### wait for jobs to finish
for job in `jobs -p` ; do
    wait \$job
done

## archive the logs
result=\$?

for d in ./OCIntegrationTestsResults* ; do
    if [ -d \$d ] ; then
        target_zip="`basename \$d`_\${result}.tar.gz"
        tar --gzip -cvf \$target_zip \$d
    fi
done

find . -maxdepth 1 -name '*.tar.gz' -type f -print0 | xargs -0r mv -t /var/lib/jenkins/archived_logs/

cat > README <<'EOF'

Logcat output, tcpdump files are archived locally since these files are huge and it's not a good idea to publish them to remote jenkins.

You can find them on PC: 10.40.31.223:/var/lib/jenkins/archived_logs/

EOF