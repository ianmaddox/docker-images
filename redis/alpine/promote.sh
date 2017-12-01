#!/usr/bin/env bash
NEWMASTER=$1
kubectl label --overwrite pod $NEWMASTER role=master