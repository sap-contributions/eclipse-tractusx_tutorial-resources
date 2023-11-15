resource "kubernetes_persistent_volume_claim" "minio-pv-claim" {
  metadata {
    name      = "${var.humanReadableName}-minio-pv-claim"
    labels = {
      app = "${var.humanReadableName}-minio-storage-claim"
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

resource "kubernetes_deployment" "minio" {
  metadata {
    name      = "${var.humanReadableName}-minio"
    labels = {
      app = "${var.humanReadableName}-minio"
    }
  }

  spec {
    # replicas = 2
    selector {
      match_labels = {
        app = "${var.humanReadableName}-minio"
      }
    }
    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app = "${var.humanReadableName}-minio"
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
            container_port = var.minio-api-port
           // host_port      = var.minio-api-port
          }
          port {
            container_port = var.minio-console-port
          //  host_port      = var.minio-console-port
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



locals {
  minio-seed_collection_name = "testdocument.txt"
  minio-ip                   = kubernetes_service.minio-service.spec.0.cluster_ip
  minio-port                 = kubernetes_service.minio-service.spec.0.port.0.port
  minio-url                  = "${local.minio-ip}:${local.minio-port}"
  minio-password             = "qwerty123"
  minio-username             = "qwerty123"
  bucket-name                =  var.bucket-name
}
