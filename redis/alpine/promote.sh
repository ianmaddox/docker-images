#!/usr/bin/env bash
NEWMASTER=$1
kubectl label --overwrite pod $NEWMASTER redis-master="true"
kubectl label --overwrite pod $NEWMASTER redis-slave="false"
