#!/bin/bash

# for loop
#for line in `cat dummy_config | grep -v "#"`; do
#line=`grep "Max_mismatch" dummy_config | grep -v "#"`
for line in `grep -v "#" dummy_config | grep -E "^.*$"`; do
	echo $line
	field=`echo $line | sed 's/^.*\t//'`
	setting=`echo $line | sed 's/\t.*$//'`
	echo "field is $field"
	echo "setting is $setting
	"



done

# find and replace command that works.  Need to integrate this into a for loop
#  sed -ri 's/^Threads_mcf.*/Threads_mcf\t20/' dummy_config 
#
## max_mismatch=(`grep "Max_mismatch" $config | grep -v "#" | cut -f 2`)
