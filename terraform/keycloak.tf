resource "random_password" "keycloak_client_secret" {
  length = 32
  upper  = true
  lower  = true
}

resource "kubernetes_deployment" "keycloak" {
  metadata {
    name      = local.keycloak_name
    namespace = kubernetes_namespace.support.metadata[0].name
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = local.keycloak_name
      }
    }

    template {
      metadata {
        labels = {
          app = local.keycloak_name
        }
      }

      spec {
        container {
          name  = local.keycloak_name
          image = "zhmash/custom-keycloak:latest"

          env {
            name  = "KC_DB_URL"
            value = "jdbc:postgresql://keycloak-postgres-service:5432/postgres"
          }

          env {
            name = "KC_DB_USERNAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.keycloak_postgres.metadata[0].name
                key  = "POSTGRES_USER"
              }
            }
          }

          env {
            name = "KC_DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.keycloak_postgres.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          env {
            name = "KC_DB_SCHEMA"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.keycloak_postgres.metadata[0].name
                key  = "POSTGRES_SCHEMA"
              }
            }
          }

          env {
            name  = "KC_FEATURES"
            value = "import_export"
          }

          env {
            name  = "KEYCLOAK_ADMIN"
            value = "Admin"
          }

          env {
            name  = "KEYCLOAK_ADMIN_PASSWORD"
            value = random_password.keycloak_db_admin_password.result
          }

          port {
            container_port = 8080
          }

          volume_mount {
            name       = "keycloak-import"
            mount_path = "/opt/keycloak/data/import"
            read_only  = true
          }

          resources {
            limits = {
              memory = "512Mi"
            }
          }
        }

        volume {
          name = "keycloak-import"
          config_map {
            name = "keycloak-import-config"
          }
        }
      }
    }
  }
}

# Service для keycloak
resource "kubernetes_service" "keycloak_service" {
  metadata {
    name      = "keycloak-service"
    namespace = kubernetes_namespace.support.metadata[0].name
  }

  spec {
    selector = {
      app = local.keycloak_name
    }

    port {
      port        = 8080
      target_port = 8080
      node_port   = 30002
    }

    type = "NodePort"
  }
}

resource "kubernetes_config_map" "keycloak_import_config" {
  metadata {
    name      = "keycloak-import-config"
    namespace = kubernetes_namespace.support.metadata[0].name
  }

  data = {
    "realm-export.json" = file("/home/dany0k/redcollar/support/docker/keycloak/import/realm-export.json")
  }
}