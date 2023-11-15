
resource "kubernetes_service" "minio-service" {
  metadata {
    name      = "${var.humanReadableName}-minio"
  }
  spec {
    type = "NodePort"
    selector = {
      app = "${var.humanReadableName}-minio"
    }
    port {
      name = "minio-api"
      port = var.minio-api-port

    }
    port {
      name = "minio-interface"
      port = var.minio-console-port
    }
  }
}