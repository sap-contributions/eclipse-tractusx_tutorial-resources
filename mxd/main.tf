#
#  Copyright (c) 2023 Contributors to the Eclipse Foundation
#
#  See the NOTICE file(s) distributed with this work for additional
#  information regarding copyright ownership.
#
#  This program and the accompanying materials are made available under the
#  terms of the Apache License, Version 2.0 which is available at
#  https://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#  License for the specific language governing permissions and limitations
#  under the License.
#
#  SPDX-License-Identifier: Apache-2.0
#

terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    // for generating passwords, clientsecrets etc.
    random = {
      source = "hashicorp/random"
    }

    keycloak = {
      source  = "mrparkers/keycloak"
      version = "4.3.1"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# First connector
module "alice-connector" {
  depends_on        = [module.alice-minio]
  source            = "./modules/connector"
  humanReadableName = "alice"
  participantId     = var.alice-bpn
  database-host     = local.pg-ip
  database-name     = "alice"
  database-credentials = {
    user     = "postgres"
    password = "postgres"
  }
  ssi-config = {
    miw-url            = "http://${kubernetes_service.miw.metadata.0.name}:${var.miw-api-port}"
    miw-authorityId    = var.miw-bpn
    oauth-tokenUrl     = "http://${kubernetes_service.keycloak.metadata.0.name}:${var.keycloak-port}/realms/miw_test/protocol/openid-connect/token"
    oauth-clientid     = "alice_private_client"
    oauth-secretalias  = "client_secret_alias"
    oauth-clientsecret = "alice_private_client"
  }
  minio-config = {
    minio-url                      = module.alice-minio.minio-url
    minio-username                 = module.alice-minio.minio-username
    minio-password                 = module.alice-minio.minio-password
    minio-secret-alias             = "minio-secret-alice"
    minio-temp-access-key          = "894D5IM0L3D76CLZA1KE"
    minio-temp-secret-access-key   = "ETlOcuWRxd9pSheCu1+kKfyjmXJDGMVywUpDioQl"
    minio-temp-secret-access-token = "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhY2Nlc3NLZXkiOiI4OTRENUlNMEwzRDc2Q0xaQTFLRSIsImV4cCI6MTcyMDAwMjk1NCwicGFyZW50IjoicXdlcnR5MTIzIn0.4_1AOBsx2QOYto-OJ7alv_o8Tbs5C5ExuB5O4k725vK_p9y34Es7VKkqJuhk4YZppZ3JCLPKIZbqgWM8GLx0hA"
  }
}

# Second connector
module "bob-connector" {
  depends_on        = [module.bob-minio]
  source            = "./modules/connector"
  humanReadableName = "bob"
  participantId     = var.bob-bpn
  database-host     = local.pg-ip
  database-name     = "bob"
  database-credentials = {
    user     = "postgres"
    password = "postgres"
  }
  ssi-config = {
    miw-url            = "http://${kubernetes_service.miw.metadata.0.name}:${var.miw-api-port}"
    miw-authorityId    = var.miw-bpn
    oauth-tokenUrl     = "http://${kubernetes_service.keycloak.metadata.0.name}:${var.keycloak-port}/realms/miw_test/protocol/openid-connect/token"
    oauth-clientid     = "bob_private_client"
    oauth-secretalias  = "client_secret_alias"
    oauth-clientsecret = "bob_private_client"
  }
  minio-config = {
    minio-url                      = module.bob-minio.minio-url
    minio-username                 = module.bob-minio.minio-username
    minio-password                 = module.bob-minio.minio-password
    minio-secret-alias             = "minio-secret-bob"
    minio-temp-access-key          = "DJMMRMKO9IALWS853XB9"
    minio-temp-secret-access-key   = "bqGB0oOkb44O0CNhF4w1KDcagFbfrLAskcydHAWa"
    minio-temp-secret-access-token = "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhY2Nlc3NLZXkiOiJESk1NUk1LTzlJQUxXUzg1M1hCOSIsImV4cCI6MTcyMDAwMzMwMCwicGFyZW50IjoicXdlcnR5MTIzIn0.VneysXnWIxvPImufOvsDZrzVwueAgYyAatQ0Sh-417k6_BUoJDaBnH_Bu1oXusdfqFWlIWQVLApIUB3-U9EpKw"
  }

}

module "alice-minio" {
  source             = "./modules/minio"
  humanReadableName  = "alice"
  pre-populate-asset = true
  minio-username     = "qwerty123"
  minio-password     = "qwerty123"
}

module "bob-minio" {
  source            = "./modules/minio"
  humanReadableName = "bob"
  minio-username    = "qwerty123"
  minio-password    = "qwerty123"
}
