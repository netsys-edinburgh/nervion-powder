#!/bin/bash

while true
do
  kubectl get hpa | tail -1 | ts '%Y-%m-%d_%H-%M-%S' >> ~/hpa.log
  sleep 1
done
