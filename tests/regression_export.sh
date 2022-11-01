#!/bin/bash

testdir=/tmp/material_maker_test
outputdir=$testdir/$(date +%s)/
mm_command="godot --no-window --path ."


if [[ $# -lt 1 ]]; then
	echo "Example Usage:"
	echo
	echo "	$0 --size 512 material_maker/examples/*.ptex"
	echo
	echo "The --size argument is optional but highly recommended to speed up testing."
	echo
	exit
fi


mkdir -p $outputdir
$mm_command --export-material -o $outputdir "$@"
cd $outputdir

echo

if [[ -e $testdir/mm.sha ]]; then
	echo "Checksums found, testing for regressions..."
	echo
	shasum -c $testdir/mm.sha
	result=$?
	echo
	if [[ $result -eq 0 ]]; then
		echo "Done! No regressions found."
		echo "To start a new test, you can remove the testing directory:"
		echo
		echo "	rm -r $testdir"
		echo
	else
		exit $result
	fi
else
	echo "Creating checksums..."
	echo
	shasum * | tee $testdir/mm.sha
	echo
	echo "Done! Rerun this script after making your changes to test for regressions."
	echo "Please be sure to use the exact same arguments to avoid triggering any false positives."
	echo "You may want to double check the exported textures for rendering errors:"
	echo
	echo "	xdg-open $outputdir"
	echo
fi


