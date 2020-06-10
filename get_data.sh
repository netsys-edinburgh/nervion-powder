#!/bin/bash

PID=$1
LOG=./$PID.log

while true; do
    ps --pid $PID -o %cpu= >> $LOG
    sleep 0.05
done