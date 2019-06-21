#!/bin/bash

for remote_file in $(find .); do
	home_path=$(echo $HOME | sed 's/\//\\\//g')
	if [ -f $remote_file ]; then
		local_file=$(echo $remote_file | sed "s/^\./$home_path/");
		if [ -f $local_file ]; then
			local_hash=$(md5sum $local_file | sed "s/\ .*//g");
			remote_hash=$(md5sum $remote_file | sed "s/\ .*//g");
			# echo $remote_file;
			# echo $local_file;
			echo $remote_hash;
			echo $local_hash;
			if [[ $local_hash != $remote_hash ]]; then
				vimdiff $local_file $remote_file;
				# echo "different";
			fi
			echo "==============================";
		fi
	fi
done
