#!/bin/bash

SCRIPTNAME=`basename $0`
exec > ${HOSTNAME%%\.*}.$SCRIPTNAME.out.`date +"%Y%m%d%H%M%S"` 2>&1

date
hostname
lscpu
numactl --hardware
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

$java \
-Xms8192m -Xmx8192m $xss_value -XX:+UseParallelOldGC $aggressive -XX:+UseBiasedLocking -XX:+UseCompressedOops -XX:SurvivorRatio=24 spec.jbb.JBBmain -propfile $PROPS_FILE
date
