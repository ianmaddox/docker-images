# Push some helpful vars into labels
PODIP=`hostname -i`
echo podIP $PODIP
kubectl label --overwrite pod $HOSTNAME podIP="$PODIP"

RUNID=""
while true; do
  RUNID=`redis-cli info server |grep run_id|awk -F: '{print $2}'|head -c6`
  if [ -n "$RUNID" ]; then
    kubectl label --overwrite pod $HOSTNAME runID="$RUNID"
    break
  else
    sleep 1
  fi
done

# Start a daemon loop to keep the redis-role label updated
ROLE=""
LASTROLE="pending"
while true; do
  ROLE=`redis-cli info replication |grep role|awk -F: '{print $2}'|xargs`
  if [ "$LASTROLE" != "$ROLE" ]; then
    echo "Role changed from '$LASTROLE' to '$ROLE'"
    kubectl label --overwrite pod $HOSTNAME redis-role="$ROLE"
    LASTROLE=$ROLE
  fi
  sleep 1
done