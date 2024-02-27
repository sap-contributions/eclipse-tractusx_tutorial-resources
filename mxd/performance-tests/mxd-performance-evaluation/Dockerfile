FROM justb4/jmeter:5.5

WORKDIR $JMETER_HOME/mxd-performance-evaluation

COPY ["run_experiment.sh", "setup.jmx", "measurement_interval.jmx", "./"]

ENTRYPOINT ["./run_experiment.sh"]
