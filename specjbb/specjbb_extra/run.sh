#!/bin/bash

SCRIPTNAME=`basename $0`
#exec > ${HOSTNAME%%\.*}.$SCRIPTNAME.out.`date +"%Y%m%d%H%M%S"`_jvm_${2}_of_${3} 2>&1
exec > ${HOSTNAME%%\.*}.$SCRIPTNAME.out.${4}_jvm_${2}_of_${3} 2>&1


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

wcpus=`cat /proc/cpuinfo | grep processor | wc -l`
wcpus=`echo "${wcpus}*2" | bc`
PROPS_FILE=prop.file

echo $CLASSPATH
CLASSPATH=./jbb.jar:./check.jar:$CLASSPATH
echo $CLASSPATH
export CLASSPATH
java=$1

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

#
# We need to increase the stack size when wcpus is over 256.  The smaller stack size
# will cause specjbb to terminate early.  We do not want to make the larger stack
# size as it will cause issues with the smaller cloud systems.
#
if [ $wcpus -gt 256 ]; then
	stacksize=16384m
else
	stacksize=8192m
fi
$java -Xms${stacksize} -Xmx${stacksize} spec.jbb.JBBmain -propfile $PROPS_FILE
date
exit $?
