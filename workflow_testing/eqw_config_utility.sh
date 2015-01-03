#!/bin/bash

## Utility to configure the config file required for my qiime workflow to function nicely

## Needs help info and usage still...

## Set working directory
	workdir=(`pwd`)

## Check for config file (current directory only for now)

configsearch=(`ls eqw*.config 2>/dev/null`)
echo $configsearch
if [[ ! -f $configsearch ]]; then
	echo "		No config file detected in local directory.
		Shall I create one for you (yes or no)?"
		read yesno
	
		if [[ ! $yesno == "yes" && ! $yesno == "no" ]]; then
		echo "		Invalid entry.  Yes or no only."
		read yesno
		if [[ ! $yesno == "yes" && ! $yesno == "no" ]]; then
		echo "		Invalid entry.  Exiting.
		"
		exit 1
		fi
		fi

		if [[ $yesno == "yes" ]]; then
		echo "		OK.  Creating workflow file in your current
		directory.
		($workdir/qiime_workflow.config)
		"
		cat blank_config.config > $workdir/eqw.config
		configfile=($workdir/eqw.config)
		fi

		if [[ $yesno == "no" ]]; then
		echo "		OK.  Please enter the path of the
		config file you want to update.
		"
		read -e configfile
		fi
	else
	foundconfig=(`ls eqw.config 2>/dev/null`)
	echo "		Found config file."
	echo "		$workdir/$foundconfig
	"
	sleep 1
	configfile=($workdir/$foundconfig)
fi
	echo "		Reading configurable fields...
	"
	sleep 1
	cat $configfile | grep -v "#" | grep -E -v '^$'

	echo "
		I will now go through each configurable field and require
		your input.  Press enter to retain the current value or 
		enter a new value.  When entering paths (say to gg database)
		remember to use tab-autocomplete to avoid errors.
	"



for field in `grep -v "#" $configfile | cut -f 1`; do
	fielddesc=`grep $field $configfile | grep "#" | cut -f 2-3`

	echo "		Field: $fielddesc"
	setting=`grep $field $configfile | grep -v "#" | cut -f 2`
	echo "		Current setting is: $setting
		Enter new value (or press enter to keep current setting):
	"
	read -e newsetting
	if [[ ! -z "$newsetting" ]]; then
	sed -i -e "s@^$field\t$setting@$field\t$newsetting@" $configfile
	echo "		Setting changed.
	"
	else
	echo "		Setting unchanged.
	"
	fi
done

echo "		$configfile updated.
"
