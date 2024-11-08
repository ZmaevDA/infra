resource "random_string" "support_db_admin_username" {
  length  = 16
  special = false
  lower   = true
}

resource "random_password" "support_db_admin_password" {
  length  = 16
  special = false
  upper   = true
  lower   = true
}

resource "kubernetes_secret" "support_db" {
  metadata {
    name      = "support-db-secret"
    namespace = kubernetes_namespace.support.metadata[0].name
  }

  data = {
    POSTGRES_USER     = random_string.support_db_admin_username.result
    POSTGRES_PASSWORD = random_password.support_db_admin_password.result
    POSTGRES_DB       = local.support_db_name
  }
}

resource "kubernetes_deployment" "support_db" {
  metadata {
    name      = local.support_db_name
    namespace = kubernetes_namespace.support.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = local.support_db_name
      }
    }

    template {
      metadata {
        labels = {
          app = local.support_db_name
        }
      }

      spec {
        container {
          name  = "postgres"
          image = "postgres:14-alpine"

          env {
            name = "POSTGRES_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.support_db.metadata[0].name
                key  = "POSTGRES_USER"
              }
            }
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.support_db.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          env {
            name = "POSTGRES_DB"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.support_db.metadata[0].name
                key  = "POSTGRES_DB"
              }
            }
          }

          resources {
            limits = {
              memory = "256Mi"
            }
          }

          volume_mount {
            name       = "postgres-storage"
            mount_path = "/var/lib/postgresql/data"
          }

          port {
            container_port = 5432
          }
        }

        volume {
          name = "postgres-storage"

          persistent_volume_claim {
            claim_name = "postgres-pv-claim"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "support_db_service" {
  metadata {
    name      = "support-db-service"
    namespace = kubernetes_namespace.support.metadata[0].name
  }

  spec {
    selector = {
      app = local.support_db_name
    }

    port {
      port        = 5432
      target_port = 5432
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_persistent_volume_claim" "postgres_pv_claim" {
  metadata {
    name      = "postgres-pv-claim"
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