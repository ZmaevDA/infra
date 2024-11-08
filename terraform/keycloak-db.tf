resource "random_string" "keycloak_db_admin_username" {
  length  = 16
  special = false
  lower   = true
}

resource "random_password" "keycloak_db_admin_password" {
  length  = 16
  special = false
  upper   = true
  lower   = true
}

resource "kubernetes_secret" "keycloak_postgres" {
  metadata {
    name      = "keycloak-postgres-secret"
    namespace = kubernetes_namespace.support.metadata[0].name
  }

  data = {
    POSTGRES_USER     = random_string.keycloak_db_admin_username.result
    POSTGRES_PASSWORD = random_password.keycloak_db_admin_password.result
    POSTGRES_DB       = "postgres"
    POSTGRES_SCHEMA   = "public"
  }
}

resource "kubernetes_deployment" "keycloak_postgres" {
  metadata {
    name      = local.keycloak_db_name
    namespace = kubernetes_namespace.support.metadata[0].name
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = local.keycloak_db_name
      }
    }

    template {
      metadata {
        labels = {
          app = local.keycloak_db_name
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
                name = kubernetes_secret.keycloak_postgres.metadata[0].name
                key  = "POSTGRES_USER"
              }
            }
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.keycloak_postgres.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          env {
            name = "POSTGRES_DB"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.keycloak_postgres.metadata[0].name
                key  = "POSTGRES_DB"
              }
            }
          }

          port {
            container_port = 5432
          }

          volume_mount {
            name       = "postgres-storage"
            mount_path = "/var/lib/postgresql/data"
          }

          resources {
            limits = {
              memory = "256Mi"
            }
          }
        }

        volume {
          name = "postgres-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.keycloak_postgres_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "keycloak_postgres_service" {
  metadata {
    name      = "keycloak-postgres-service"
    namespace = kubernetes_namespace.support.metadata[0].name
  }

  spec {
    selector = {
      app = local.keycloak_db_name
    }

    port {
      port        = 5432
      target_port = 5432
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_persistent_volume_claim" "keycloak_postgres_pvc" {
  metadata {
    name      = "keycloak-postgres-pvc"
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

