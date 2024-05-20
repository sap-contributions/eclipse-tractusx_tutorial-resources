#!/bin/bash
experiment_property="mount/custom_experiment.properties"

if [ -z "$JMETER_HOME" ]; then
  echo "JMETER_HOME is not defined - please define it."
  exit 1  
fi
echo "Jmeter found at path $JMETER_HOME"

jmeter_binary="$JMETER_HOME/bin/jmeter"

rm -rf output
mkdir -p output/dashboard

rm -rf output_slim
mkdir -p output_slim/dashboard

rm -rf output_jtl
mkdir -p output_jtl

echo "*** Property: $experiment_property Start ***"
cat $experiment_property
echo "*** Property: $experiment_property End ***"

echo "*** Performance Test Start ***"
if [ -z "$jmeter_script" ]; then
  echo "Executing all scripts in order"
  echo "Executing setup.jmx"
  $jmeter_binary -n -t mount/setup.jmx -l output_jtl/setup.jtl -q $experiment_property -j "output/setup_jmeter.log"
  echo "Executing measurement_interval.jmx"
  $jmeter_binary -n -t mount/measurement_interval.jmx -l output_jtl/measurement_interval.jtl -q $experiment_property \
    -j "output/measurement_interval_jmeter.log" -e -o output/dashboard
fi
echo "*** Performance Test End ***"

echo "Copying custom_experiment.properties to output folder with new name metadata.txt"
cp $experiment_property output/metadata.txt
echo "Creating tar file with output"
tar -cf output.tar output

echo "Copying custom_experiment.properties to output_slim folder with new name metadata.txt"
cp $experiment_property output_slim/metadata.txt
echo "Copying output/dashboard/statistics.json to output_slim/dashboard/statistics.json folder"
cp output/dashboard/statistics.json output_slim/dashboard/statistics.json
echo "Creating tar file with output"
tar -cf output_slim.tar output_slim

tar -czf output_jtl.tar.gz output_jtl

echo "*** Test Completed..., Sleeping now ***"
while true; do sleep 10000; done
