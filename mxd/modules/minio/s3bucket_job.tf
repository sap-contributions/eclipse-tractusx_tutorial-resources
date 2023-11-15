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

resource "kubernetes_job" "create_minio_bucket" {
  depends_on = [kubernetes_deployment.minio, kubernetes_service.minio-service]
  metadata {
    name = "${var.humanReadableName}-create-minio-bucket"
  }
  spec {
    ttl_seconds_after_finished = "90"
    completions                = 1
    completion_mode            = "NonIndexed"
    template {
      metadata {
        name = "${var.humanReadableName}-create-minio-bucket"
      }
      spec {
        container {
          name    = "minio-client"
          image   = "minio/mc:latest" # Use the appropriate MinIO client image
          command = ["/bin/sh", "-c"]
          args    = ["mc config host add minio http://${local.minio-url} ${local.minio-username} ${local.minio-password} && mc mb minio/${local.bucket-name}"]
        }
      }
    }
  }
}

resource "kubernetes_job" "put-text-document" {
  count = var.pre-populate-asset ? 1 : 0
  depends_on = [kubernetes_deployment.minio,
    kubernetes_service.minio-service,
    kubernetes_job.create_minio_bucket,
  kubernetes_config_map.minio-seed-collection]

  metadata {
    name = "put-text-document"
  }

  spec {
    ttl_seconds_after_finished = "90"
    completions                = 1
    completion_mode            = "NonIndexed"
    template {
      metadata {
        name = "put-text-document"
      }
      spec {
        container {
          name    = "mc"
          image   = "minio/mc"
          command = ["/bin/sh", "-c"]
          args    = ["mc config host add minio http://${local.minio-url} ${local.minio-username} ${local.minio-password} && mc cp /opt/config/${local.minio-seed_collection_name} minio/${local.bucket-name}/document.txt"]
          volume_mount {
            name       = "minio-seed-collection"
            mount_path = "/opt/config"
          }
          env {
            name  = "MC_HOSTS"
            value = local.minio-url # MinIO service hostname and port
          }
          env {
            name  = "MINIO_ROOT_USER"
            value = local.minio-username
          }
          env {
            name  = "MINIO_ROOT_PASSWORD"
            value = local.minio-password
          }
        }
        volume {
          name = "minio-seed-collection"
          config_map {
            name = kubernetes_config_map.minio-seed-collection[count.index].metadata.0.name
          }
        }
        restart_policy = "Never"
      }
    }
  }
}

resource "kubernetes_config_map" "minio-seed-collection" {
  count = var.pre-populate-asset ? 1 : 0
  metadata {
    name = "minio-seed-collection"
  }
  data = {
    (local.minio-seed_collection_name) = file("./assets/testdocument.txt")
  }
}