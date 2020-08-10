#!/bin/bash

sudo ps aux | grep supervisor | awk '{print $2}' | xargs kill -9
sudo ps aux | grep nimbus | awk '{print $2}' | xargs kill -9
sudo ps aux | grep "Ddaemon.name=ui" | awk '{print $2}' | xargs kill -9
