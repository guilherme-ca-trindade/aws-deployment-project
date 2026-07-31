#!/bin/bash

# This gets run ON the EC2 instance (NOT in the GitHub Actions runner)

# -e : exit immediately on error
# -u : treat unset variables as an error
# -x : print the commands as they get executed (so they show up in GitHub Actions logs)
set -eux

cd /home/ec2-user/dice

git fetch --all
git switch gui-branch # Your lab branch name here

sudo systemctl restart diceapp
sudo systemctl status diceapp --no-pager -l
