# Performance Tests run 

### 1. Introduction
```run-sml.sh```  deploys terraform from ```mxd```folder and starts the ```mxd-performance-test``` container 
which runs ```small_experiment.properties``` with a fresh docker image created with latest changes from .jmx files. 

### 2. Prerequisites
Authenticate in docker
```docker login```

### 3. Examples

#### Display help
```./run-sml.sh -x```

#### Run all files from test-configurations folder
```./run-sml.sh -h myDockerID```

#### Run just one file ex:  medium_experiment_10_contracts.properties
```./run-sml.sh -h myDockerID -f test-configurations/medium_experiment_10_contracts.properties```



