#!/bin/bash

GPG_TTY=$(tty)
export GPG_TTY

cd /Users/ciprian/IdeaProjects/Connector
./gradlew clean build -x test -x checkstyleMain -x checkstyleTest
./gradlew publishToMavenLocal

echo "+++++++++++++Input password pressing same char multiple times if star does not appear"

cd /Users/ciprian/IdeaProjects/tractusx-edc
./gradlew dockerize -x test -x checkstyleMain -x checkstyleTest --stacktrace

docker tag edc-controlplane-postgresql-hashicorp-vault ciprian2398/edc-controlplane-postgresql-hashicorp-vault:0.6.0
docker image push ciprian2398/edc-controlplane-postgresql-hashicorp-vault:0.6.0

docker tag edc-dataplane-hashicorp-vault ciprian2398/edc-dataplane-hashicorp-vault:0.6.0
docker image push ciprian2398/edc-dataplane-hashicorp-vault:0.6.0

cd /Users/ciprian/IdeaProjects/tutorial-resources/mxd/performance-tests

echo "+++++++++++++running the experiment"
./experiment_controller.sh -f test-configurations/Business_Case_Tier5.properties -x shoot--edc-lpt--mxd -y shoot--edc-lpt--mxd
