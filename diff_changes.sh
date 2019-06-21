#!/bin/bash

for remote_file in $(find .); do
	home_path=$(echo $HOME | sed 's/\//\\\//g')
	if [ -f $remote_file ]; then
		local_file=$(echo $remote_file | sed "s/^\./$home_path/");
		if [ -f $local_file ]; then
			local_hash=$(md5sum $local_file | sed "s/\ .*//g");
			remote_hash=$(md5sum $remote_file | sed "s/\ .*//g");
			if [[ $local_hash != $remote_hash ]]; then
				vimdiff $local_file $remote_file;
			fi
		fi
	fi
done
