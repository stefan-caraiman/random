#!/bin/bash

COLLECT_INTERVAL=15

# Note: when printing to STDOUT the metric, 
# make sure there are no extra spaces between params as it will not intrepret the output.
# Also: for any new metric, it is advised to add them to opentsdb as it follows:
# `./tsdb mkmetric metric jvm.gc.full_gc_occurrence` tsdb binary can be found in the build folder

while :; do
  # Making sure we are getting the right Java PID by comparing the PID's fetched
  # with jps and pgrep. java
  jps_pids=($(jps | awk '{print $1}'))
  pgrep_pids=($(pgrep java | awk '{print $1}'))
  pgrep_pids=" ${pgrep_pids[*]} "
  for pid in ${jps_pids[@]}; do
    if [[ $pgrep_pids =~ " $pid " ]] ; then
      java_pid=($pid)
    fi
  done

  # If there were no other Java process(dead or zombie) a single PID will be fetched
  # FGC The number of full GC event occurred (13 colloumn when using gc)
  # FGCT  The accumulated time for full GC operations (14)
  # GCT The total accumulated time for GC operations (15)
  epoch=`date +%s`
  host_tag=`hostname -s`
  total_time_gc=($(jstat -gc ${java_pid} | awk 'NR==2{print $15}'))
  total_time_full_gc=($(jstat -gc ${java_pid} | awk 'NR==2{print $14}'))
  full_gc_occurrence=($(jstat -gc ${java_pid} | awk 'NR==2{print $13}'))

  echo "jvm.gc.total_time_gc ${epoch} ${total_time_gc} host=${host_tag}"
  echo "jvm.gc.total_time_full_gc ${epoch} ${total_time_full_gc} host=${host_tag}"
  echo "jvm.gc.full_gc_occurrence ${epoch} ${full_gc_occurrence} host=${host_tag}"

  sleep $COLLECT_INTERVAL
done
exit 0

