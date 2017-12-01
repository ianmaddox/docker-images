#!/usr/bin/env bash
NEWMASTER=$1
kubectl label --overwrite pod $NEWMASTER redis-master="true"

#todo: Monitor the replica pool. Once there are servers other than $NEWMASTER in there, remove the redis-slave flag
#kubectl label --overwrite pod $NEWMASTER redis-master="true"
