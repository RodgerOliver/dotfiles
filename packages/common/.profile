#!/bin/bash

# bash running
if [ -n "$BASH_VERSION" ]; then
	# source .bashrc
	if [ -f ~/.bashrc ]; then
		. ~/.bashrc
	fi
fi
