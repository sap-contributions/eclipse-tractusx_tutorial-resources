# Performance Tests run 

### 1. Introduction
The script ```./run-sml.sh```  
1. Deploys terraform from ```mxd```folder to remote cluster 
2. Starts the ```mxd-performance-test``` container in the local cluster 
which runs ```small_experiment.properties``` by default with a fresh docker image created with latest changes from .jmx files. 

### 2. Prerequisites
1. Install Docker and authenticate with ```docker login```

2. Make mxd-performance-test image public on your docker hub

3. Install kind and run ```kind create cluster -n mxd```, this will create a local cluster named ```kind-mxd```
which is the default cluster name used in the script for hosting the performance test pod.

4The second cluster ```shoot--edc-lpt--mxd```  is the remote cluster used to host other pods ex:(alice,bob,etc..).

After you get the remote kube/config file, merge both files in one as described [here](https://blog.thenets.org/managing-multiples-kubernetes-clusters-with-kubectl/).

Make sure you use ```shoot--edc-lpt--mxd``` and ```kind-mxd``` as context names or change them with -x -y flags.

### 3. Examples

#### Display help
```./run-sml.sh -x```

#### Run default file small_experiment.properties
```./run-sml.sh -h myDockerID```

#### Run all files from test-configurations folder
```./run-sml.sh -h myDockerID -f test-configurations```

#### Run just one file ex:  medium_experiment_10_contracts.properties
```./run-sml.sh -h myDockerID -f test-configurations/medium_experiment_10_contracts.properties```

#### Run large_experiment.properties with test pod on cluster from shoot--ciprian--test-cluster context
```./run-sml.sh -h ciprian2398 -f test-configurations/large_experiment.properties -x shoot--ciprian--test-cluster```



