#!/bin/bash

java=""
stack_size=""
jvm_of=1
total_jvms=1

NOARG_OPTS=(
)

ARG_OPTS=(
    "java_exec"
    "jvm_number"
    "stack_size"
    "total_jvms"
)

opts=$(getopt \
    --longoptions "$(printf "%s," "${NOARG_OPTS[@]}")" \
    --longoptions "$(printf "%s:," "${ARG_OPTS[@]}")" \
    --name "$(basename "$0")" \
    --options "hc:" \
    -- "$@"
)

if [ $? -ne 0 ]; then
	echo No arguments
        exit 1
fi

eval set --$opts
while [[ $# -gt 0 ]]; do
        case "$1" in
		--java_exec)
			java=$2
			shift 2
		;;
		--jvm_number)
			jvm_of=$2
			shift 2
		;;
		--stack_size)
			stack_size=$2
			shift 2
		;;
		--total_jvms)
			total_jvms=$@
			shift 2
		;;
		--)
			break
                ;;
                *)
			echo Unknown option $1
			exit 1
		;;
	esac
done

SCRIPTNAME=`basename $0`
#exec > ${HOSTNAME%%\.*}.$SCRIPTNAME.out.`date +"%Y%m%d%H%M%S"`_jvm_${jvm_of}_of_${total_jvms} 2>&1
exec > ${HOSTNAME%%\.*}.$SCRIPTNAME.out.${total_jvms}_jvm_${jvm_of}_of_${total_jvms} 2>&1


date
hostname
lscpu
numactl --hardware
if [ $? -ne 0 ]; then
	echo Warning, unable to obtain numa hardware info.
fi
cat /proc/meminfo
cat /etc/*release
uname -a
cat /proc/cmdline
tuned-adm list
cat /sys/kernel/debug/sched_features
grep -H '.' /sys/kernel/debug/x86/*enabled
find /proc/sys/kernel -type f -exec grep -H  '.' {} \;
find /proc/sys/vm     -type f -exec grep -H  '.' {} \;
find /sys/kernel/mm   -type f -exec grep -H  '.' {} \;
sysctl -a | sort
ps -ef | grep -i numa

PROPS_FILE=prop.file

echo $CLASSPATH
CLASSPATH=./jbb.jar:./check.jar:$CLASSPATH
echo $CLASSPATH
export CLASSPATH

$java -fullversion

$java -version 2> java_version
java_version=`grep "openjdk version" java_version | cut -d'"' -f 2`
if [[ $version == "11"* ]]; then
	aggressive=""
else
	aggressive="-XX:+AggressiveOpts"
fi
cpu_type=`uname -m`
if [[ $cpu_type == "aarch64" ]]; then
	#
	# If having issues with stack size during run
	# make the change here.
	#
	 xss_value="-Xss448k"
else
	 xss_value="-Xss330k"
fi

$java -Xms${stack_size}m -Xmx${stack_size}m spec.jbb.JBBmain -propfile $PROPS_FILE
date
exit $?
