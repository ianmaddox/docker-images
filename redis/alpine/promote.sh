#!/usr/bin/env bash
NEWMASTER=$1
echo "PROMOTING $NEWMASTER TO MASTER"
kubectl label --overwrite pod $NEWMASTER redis-role="master"
