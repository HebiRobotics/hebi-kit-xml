#!/bin/sh -l

echo "This is the new action"
time=$(date)
echo "::set-output name=time::$time"

ls

echo "Checkpoint #1"
git clone git@github.com:HebiRobotics/hebi-python-examples.git
echo "Checkpoint #2"
ls 


# sh -c "echo Starting Auto-PR process"

# sh -c "mkdir test-folder"

# sh -c "echo Completed Auto-PR process"



