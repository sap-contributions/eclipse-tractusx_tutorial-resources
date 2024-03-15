# Performance Tests run 

### 1. Introduction
The script ```./experiment_controller.sh```  
1. Deploys terraform from ```mxd```folder to a provided cluster 
2. Starts the ```mxd-performance-test``` container which runs
```small_experiment.properties``` by default with latest changes from .jmx files. 

### 2. Prerequisites

#### 1. Local run 
Install kind and run ```kind create cluster -n mxd```, this will create a local cluster named ```kind-mxd```
which is the default cluster name.

#### 2. Remote run
For remote run you don't need ```kind``` just provide the name of the remote cluster in -x and -y args. 

#### 3. Remote run in two separate clusters
Collect .kube/config files and merge them in one as described [here](https://blog.thenets.org/managing-multiples-kubernetes-clusters-with-kubectl/).
Then provide the name of the remote cluster for test pod with -x arg, and name of the remote cluster for rest of pods using -y arg.

### 3. Examples
For more information about arguments visit [help.txt](help.txt)."

#### Display help
```./experiment_controller.sh -h```

#### Run default experiment file small_experiment.properties on ```kind-mxd``` cluster
```./experiment_controller.sh```

#### Run all files from test-configurations folder on ```kind-mxd``` cluster
```./experiment_controller.sh -f test-configurations```

#### Run just one file ex:  medium_experiment_10_contracts.properties  on ```kind-mxd``` cluster
```./experiment_controller.sh -f test-configurations/medium_experiment_10_contracts.properties```

#### Run default experiment file small_experiment.properties on ```shoot--edc-lpt--mxd``` cluster
```./experiment_controller.sh -x shoot--edc-lpt--mxd -y shoot--edc-lpt--mxd```

####  Run default experiment file with test container on ```kind-mxd``` cluster and the rest of the environment on ```shoot--edc-lpt--mxd``` cluster
```./experiment_controller.sh -x kind-mxd -y shoot--edc-lpt--mxd```

#### Run all files from test-configurations folder on separate clusters
```./experiment_controller.sh -f test-configurations -x kind-mxd -y shoot--edc-lpt--mxd```

