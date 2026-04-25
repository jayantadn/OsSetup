#!/usr/bin/env bash

cd "$1"
for file in `ls | grep "-eng.srt"`
do
	mv $file `echo $file | sed 's/-eng.srt/.srt/'`
done
