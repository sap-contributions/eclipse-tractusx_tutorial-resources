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


resource "kubernetes_namespace" "minio" {
  metadata {
    name = "minio"
  }
}


resource "kubernetes_persistent_volume_claim" "minio-pv-claim" {
  metadata {
    namespace = kubernetes_namespace.minio.metadata.0.name
    name      = "minio-pv-claim"
    labels = {
      app = "minio-storage-claim"
    }
  }
  wait_until_bound = false
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "20Gi"
      }
    }
  }
}

resource "kubernetes_service" "minio-service" {
  metadata {
    namespace = kubernetes_namespace.minio.metadata.0.name
    name      = "minio"
  }
  spec {
    cluster_ip = "10.96.103.86"
    port {
      protocol    = "TCP"
      name        = "minio-api"
      port        = 9000
      target_port = 9000
    }
    port {
      name        = "minio-interface"
      port        = 9001
      target_port = 9001
    }
    selector = {
      app = "minio"
    }
  }
}

resource "kubernetes_deployment" "minio" {
  metadata {
    namespace = kubernetes_namespace.minio.metadata.0.name
    name      = "minio"
    labels = {
      app = "minio"
    }
  }

  spec {
    # replicas = 2
    selector {
      match_labels = {
        app = "minio"
      }
    }
    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app = "minio"
        }
      }

      spec {
        container {
          image = "minio/minio:RELEASE.2022-03-17T06-34-49Z"
          name  = "minio"
          args  = ["server", "/storage", "--console-address=:9001"]
          env {
            name  = "MINIO_ROOT_USER"
            value = local.minio-username
          }
          env {
            name  = "MINIO_ROOT_PASSWORD"
            value = local.minio-password
          }
          port {
            container_port = 9000
            host_port      = 9000
          }
          port {
            container_port = 9001
            host_port      = 9001
          }
          volume_mount {
            name       = "storage"
            mount_path = "/storage"
            read_only  = false
          }

        }

        volume {
          name = "storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.minio-pv-claim.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_job" "create_minio_bucket" {
  depends_on = [kubernetes_deployment.minio, kubernetes_service.minio-service]
  metadata {
    name      = "create-minio-bucket"
    namespace = kubernetes_namespace.minio.metadata[0].name
  }
  spec {
    ttl_seconds_after_finished = "90"
    completions                = 1
    completion_mode            = "NonIndexed"
    template {
      metadata {
        name = "create-minio-bucket"
      }
      spec {
        container {
          name    = "minio-client"
          image   = "minio/mc:latest" # Use the appropriate MinIO client image
          command = ["/bin/sh", "-c"]
          args    = ["mc config host add minio http://${local.minio-url} ${local.minio-username} ${local.minio-password} && mc mb minio/alice-bucket && mc mb minio/bob-bucket"]
        }
      }
    }
  }
}


resource "kubernetes_job" "put-text-document" {
  depends_on = [kubernetes_deployment.minio,
    kubernetes_service.minio-service,
    kubernetes_job.create_minio_bucket,
  kubernetes_config_map.minio-seed-collection]

  metadata {
    name      = "put-text-document"
    namespace = kubernetes_namespace.minio.metadata.0.name
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
          args    = ["mc config host add minio http://${local.minio-url} ${local.minio-username} ${local.minio-password} && mc cp /opt/config/${local.minio-seed_collection_name} minio/alice-bucket/document.txt"]
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
            name = kubernetes_config_map.minio-seed-collection.metadata.0.name
          }
        }
        restart_policy = "Never"
      }
    }
  }
}

resource "kubernetes_config_map" "minio-seed-collection" {
  metadata {
    name      = "minio-seed-collection"
    namespace = kubernetes_namespace.minio.metadata[0].name
  }
  data = {
    (local.minio-seed_collection_name) = file("./assets/testdocument.txt")
  }
}

locals {
  minio-seed_collection_name = "testdocument.txt"
  minio-ip                   = "10.96.103.86"
  minio-port                 = "9000"
  minio-username             = "qwerty123"
  minio-password             = "qwerty123"
  minio-url                  = "${local.minio-ip}:${local.minio-port}"
  minio-realm                = "minio"
}
