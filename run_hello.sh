#!/bin/bash

testfile="$1"

if [ -z "$testfile" ]
then
	echo -e "No filename provided, defaulting to hello.c!"
	testfile="hello"
fi		

if [ ! -d "software/$testfile" ]
then
	echo "File does not exist!"
	echo "Exiting..."
	exit 1
fi

source setup.sh

echo -e "\n\nRunning run.sh!"

set -x

echo -e "\n\nMaking clean..."
cd hardware
rm -rf .bender

echo -e "\n\nRunning Bender..."
make update
make preload=1 localjtag=1 scripts_vip 


echo -e "\n\nBuilding elf file..."
cd ../software/"$testfile"
make clean all
make sim
set +x

echo -e "\n\nRun completed."
