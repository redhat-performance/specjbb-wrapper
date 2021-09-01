#!/bin/bash
#
# Takes a series of specjbb runs, combines the data files, and throws out the high point and low point for each warehouse.  It then
# averages the data, and places the output in the file spec_sum.results
#
temp_dir=/tmp/reduce_tmp_dir
rm spec_sum.results
rm -rf $temp_dir
mkdir $temp_dir
ls *txt > $temp_dir/files
input=$temp_dir/files
index=0
while IFS= read -r line
do
	input1=$line
	rm $temp_dir/temp_${index}
	found=0
	while IFS= read -r data
	do
		if [[ $data == *"Warehouses"* ]]; then
			found=1	
			continue
		fi
		if [ $found -eq 0 ]; then
			continue;
		fi
		if [[ $data == *"Through"* ]]; then
			break
		fi
		worker=${data/\*/}
		worker1=`echo $worker | xargs`
		if [ "$worker1" == $'\n' ]; then
			break;
		fi
		echo $worker1 >> $temp_dir/temp_${index}
	done < "$input1"
	# Remove the empty line
	sed '/^$/d' $temp_dir/temp_${index} > $temp_dir/temp
	mv $temp_dir/temp $temp_dir/temp_${index}
	let "index=$index + 1"
done < "$input"

# build file list
let "index=$index - 1"
for index1 in `seq 0 $index`
do
	if [ $index1 -gt 0 ]; then
		join $temp_dir/joined_files $temp_dir/temp_${index1} > $temp_dir/worker
		mv $temp_dir/worker $temp_dir/joined_files
		continue;
	fi
	cp $temp_dir/temp_${index1} $temp_dir/joined_files
done

input="$temp_dir/joined_files"
while IFS= read -r data
do
	val=`echo $data | cut -d' ' -f2-256`
	wh=`echo $data | cut -d' ' -f1`

	rm $temp_dir/worker
	for val1 in ${val}
	do
		echo $val1 >> $temp_dir/worker
	done
	sort -n $temp_dir/worker > $temp_dir/worker1
	lines=`wc -l $temp_dir/worker1 | cut -d' ' -f 1`
	let "tail_lines=$lines - 1"
	tail -$tail_lines $temp_dir/worker1 > $temp_dir/worker2
	let "head_lines=$tail_lines - 1"
	head -n $head_lines $temp_dir/worker2 > $temp_dir/worker3

	input1="$temp_dir/worker3"
	val_numb=0;
	item_numb=0
	while IFS= read -r line
	do
		let "item_numb=$item_numb + 1"
		if [ $val_numb -eq 0 ]; then
			value=$line
			val_numb=1
			continue
		fi
		let "value=$value + $line"
	done < "$input1"
	let "results=$value / $item_numb"
	echo $wh:$results >> spec_sum.results
done < "$input"
