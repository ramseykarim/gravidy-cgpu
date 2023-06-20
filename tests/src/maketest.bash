#!/bin/bash

set -e

date_time=$(TZ=":US/Eastern" date +"%Y-%m-%d_%H:%M:%S_EST")
folder_name="test_$date_time"
mkdir -p "$folder_name"
cd "$folder_name"

mkdir -p gpu1
cd gpu1

# create job.bash
cp ../../../src/job_template1.bash job.bash


# list the most recent file with the pattern test_*

