#! /bin/sh

files=$@
if [ "$1" == "-h" ] ; then
	echo "Usage:	$0 [file ...]"
	echo "	If no files are specified, all files in the current directory with extension .h, .c, and .m are checked."
	echo
	echo "Searches the specified files for the string '!!!!' and returns the location of any matches."
	exit 0
fi

if [ -z "$files" ] ; then
	tmp=`echo *.h`
	if [ "$tmp" != '*.h' ] ; then files="$tmp"; fi
	tmp=`echo *.c`
	if [ "$tmp" != '*.c' ] ; then files="$files $tmp"; fi
	tmp=`echo *.m`
	if [ "$tmp" != '*.m' ] ; then files="$files $tmp"; fi
fi

fgrep -e '!!!!' -Hn $files
