#!/bin/bash

kubectl get hpa | tail -1 | ts '%Y-%m-%d_%H-%M-%S' >> /users/s1703695/hpa.log