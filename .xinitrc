#!/bin/bash

# for executing which DE (Desktop Enviroment) or WM (Window Manager)
# session you want to startup from startx
# when there is no DM (Display Manager)
xset dpms 0 0 1200
exec i3
