#!/bin/bash

git -C $HOME/projects/clarabel/julia status

sbatch rust_compile.conf

sleep 3

watch -c squeue -u $USER
