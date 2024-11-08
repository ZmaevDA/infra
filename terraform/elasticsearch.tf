resource "kubernetes_deployment" "elasticsearch" {
  metadata {
    name      = local.elasticsearch_name
    namespace = kubernetes_namespace.support.metadata[0].name
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = local.elasticsearch_name
      }
    }

    template {
      metadata {
        labels = {
          app = local.elasticsearch_name
        }
      }

      spec {
        container {
          name  = local.elasticsearch_name
          image = "elasticsearch:8.8.2"

          env {
            name  = "discovery.type"
            value = "single-node"
          }

          env {
            name  = "node.name"
            value = "odfe-node"
          }

          env {
            name  = "discovery.seed_hosts"
            value = "odfe-node"
          }

          env {
            name  = "bootstrap.memory_lock"
            value = "true"
          }

          env {
            name  = "xpack.security.enabled"
            value = "false"
          }

          env {
            name  = "ES_JAVA_OPTS"
            value = "-Xms512m -Xmx512m"
          }

          volume_mount {
            name       = "elasticsearch-data"
            mount_path = "/usr/share/elasticsearch/data"
          }

          port {
            container_port = 9200
          }

          resources {
            requests = {
              memory = "1Gi"
              cpu    = "500m"
            }
            limits = {
              memory = "2Gi"
              cpu    = "1"
            }
          }
        }

        volume {
          name = "elasticsearch-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.elasticsearch_data.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "elasticsearch_service" {
  metadata {
    name      = local.elasticsearch_name
    namespace = kubernetes_namespace.support.metadata[0].name
  }

  spec {
    selector = {
      app = local.elasticsearch_name
    }

    port {
      port        = 9200
      target_port = 9200
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_persistent_volume_claim" "elasticsearch_data" {
  metadata {
    name      = "elasticsearch-data"
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