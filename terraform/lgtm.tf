resource "kubernetes_deployment" "lgtm" {
  metadata {
    name      = local.lgtm_name
    namespace = kubernetes_namespace.support.metadata[0].name
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = local.lgtm_name
      }
    }

    template {
      metadata {
        labels = {
          app = local.lgtm_name
        }
      }

      spec {
        container {
          name  = local.lgtm_name
          image = "grafana/otel-lgtm"

          port {
            name           = "grpc"
            container_port = 4317
          }

          port {
            name           = "http"
            container_port = 4318
          }

          port {
            name           = "grafana"
            container_port = 3000
          }

          resources {
            limits = {
              memory = "512Mi"
              cpu    = "300m"
            }
            requests = {
              memory = "512Mi"
              cpu    = "300m"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "lgtm_service" {
  metadata {
    name      = "lgtm-service"
    namespace = kubernetes_namespace.support.metadata[0].name
  }

  spec {
    selector = {
      app = local.lgtm_name
    }

    port {
      name = local.lgtm_name
      port        = 4317
      target_port = 4317
      node_port   = 31001
    }

    port {
      name = "http"
      port        = 4318
      target_port = 4318
      node_port   = 31002
    }

    port {
      name = "grafana"
      port        = 3000
      target_port = 3000
      node_port   = 31003
    }

    type = "NodePort"
  }
}