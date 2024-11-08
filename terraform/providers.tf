terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.32.0"
    }
    keycloak = {
      source = "mrparkers/keycloak"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-a"
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

provider "keycloak" {
  client_id     = var.keycloak_client_id
  client_secret = random_password.keycloak_client_secret.result
  realm         = var.keycloak_realm_name
  url           = "http://localhost:8080"
  username      = local.admin_user
  password      = random_password.keycloak_db_admin_password.result
}
