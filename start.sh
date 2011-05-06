#!/bin/bash

export PATH=/home/evalto/bin:/usr/sbin:/usr/bin:/sbin:/bin
cd ~/evalto
screen -d -m -S evalto hack evalto.recipe
