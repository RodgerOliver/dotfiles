#!/bin/bash

for remote_file in $(find . -type f ! -path './.git/*' ! -path './.icons/*'); do
	home_path=$(echo $HOME | sed 's/\//\\\//g')
		local_file=$(echo $remote_file | sed "s/^\./$home_path/");
		home_file=$(echo $remote_file | sed "s/^\./~/");
		if [ -f $local_file ]; then
			local_hash=$(md5sum $local_file | sed "s/\ .*//g");
			remote_hash=$(md5sum $remote_file | sed "s/\ .*//g");
			if [[ $local_hash != $remote_hash ]]; then
				vimdiff $remote_file $local_file;
				echo "UPDATED ${home_file}";
			fi
		else
				echo "NO FILE ${home_file}";
		fi
done
