#!/bin/sh -l

echo "This is the new action"
time=$(date)
echo "::set-output name=time::$time"

ls

# sh -c "echo Starting Auto-PR process"

# sh -c "mkdir test-folder"

# sh -c "echo Completed Auto-PR process"



