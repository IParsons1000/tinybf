#!/bin/sh
#
# (c)2025 Ira Parsons
# tinybf test suite
#

BINDIR=${1:-..}
TESTDIR=${2:-.}

completed=0

hwout=$($BINDIR/tinybf $TESTDIR/helloworld)

if [[ $hwout == $(echo Hello World!) ]]
then
	echo "[TEST] #1 (helloworld) : Success"
	completed=$(($completed+1))
else
	echo "[TEST] #1 (helloworld) : Failure"
fi

svout=$($BINDIR/tinybf $TESTDIR/seven)

if [[ $svout == "7" ]]
then
	echo "[TEST] #2 (seven)      : Success"
	completed=$(($completed+1))
else
	echo "[TEST] #2 (seven)      : Failure"
fi

rtout=$(printf 'ABC' | $BINDIR/tinybf $TESTDIR/rot13.b)

if [[ $rtout == "NOP" ]]
then
	echo "[TEST] #3 (rot13.b)    : Success"
	completed=$(($completed+1))
else
	echo "[TEST] #3 (rot13.b)    : Failure"
fi

hdout=$(cat $TESTDIR/test.sh | $BINDIR/tinybf $TESTDIR/head.b)

if [[ $hdout == $(head -n10 $TESTDIR/test.sh) ]]
then
	echo "[TEST] #4 (head.b)     : Success"
	completed=$(($completed+1))
else
	echo "[TEST] #4 (head.b)     : Failure"
fi

echo "[TEST] $completed of 4 tests completed succesfully"
