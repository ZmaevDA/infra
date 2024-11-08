resource "random_password" "rabbitmq_password" {
  length  = 16
  special = false
  upper   = true
  lower   = true
}

resource "kubernetes_persistent_volume_claim" "rabbitmq_data" {
  metadata {
    name      = "rabbitmq-data"
    namespace = kubernetes_namespace.support.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "rabbitmq" {
  metadata {
    name      = local.rabbitmq_name
    namespace = kubernetes_namespace.support.metadata[0].name
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = local.rabbitmq_name
      }
    }

    template {
      metadata {
        labels = {
          app = local.rabbitmq_name
        }
      }

      spec {
        container {
          name  = local.rabbitmq_name
          image = "rabbitmq:3-management-alpine"

          env {
            name  = "RABBITMQ_DEFAULT_USER"
            value = local.admin_user
          }

          env {
            name  = "RABBITMQ_DEFAULT_PASS"
            value = random_password.rabbitmq_password.result
          }

          port {
            container_port = 5672
          }

          port {
            container_port = 15672
          }

          volume_mount {
            name       = "rabbitmq-data"
            mount_path = "/var/lib/rabbitmq"
          }

          resources {
            limits = {
              memory = "256Mi"
            }
          }
        }

        volume {
          name = "rabbitmq-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.rabbitmq_data.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "rabbitmq_service" {
  metadata {
    name      = "rabbitmq-service"
    namespace = kubernetes_namespace.support.metadata[0].name
  }

  spec {
    selector = {
      app = local.rabbitmq_name
    }

    port {
      name        = "amqp"
      port        = 5672
      target_port = 5672
      node_port   = 30004
    }

    port {
      name        = "management"
      port        = 15672
      target_port = 15672
      node_port   = 30003
    }

    type = "NodePort"
  }
}
