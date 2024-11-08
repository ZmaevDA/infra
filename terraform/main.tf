locals {
  rabbitmq_name = "rabbitmq"
  admin_user = "admin"
  lgtm_name = "lgtm"
  keycloak_db_name = "keycloak-postgres"
  keycloak_name = "keycloak"
  elasticsearch_name = "elasticsearch"
  support_db_name = "support-db"
  security_schema_name = "my_oAuth_security_schema"
}

resource "kubernetes_namespace" "support" {
  metadata {
    name = "support"
  }
}

output "namespace_name" {
  value = kubernetes_namespace.support.metadata[0].name
}

output "keycloak_client_secret" {
  value     = random_password.keycloak_client_secret.result
  sensitive = true
}

output "keycloak_db_admin_password" {
  value     = random_password.keycloak_db_admin_password.result
  sensitive = true
}

output "keycloak_realm_name" {
  value = var.keycloak_realm_name
}

output "keycloak_client_id" {
  value = var.keycloak_client_id
  sensitive = true
}

output "keycloak_port" {
  value = kubernetes_service.keycloak_service.spec[0].port[0].node_port
}

output "oauth_security_schema" {
  value = local.security_schema_name
}

output "minikube_ip" {
  value = var.minikube_ip
}

output "db_user" {
  value     = random_string.support_db_admin_username.result
  sensitive = true
}

output "db_password" {
  value     = random_password.support_db_admin_password.result
  sensitive = true
}

output "db_name" {
  value     = local.support_db_name
  sensitive = true
}

output "db_service_host" {
  value     = kubernetes_service.support_db_service.metadata[0].name
  sensitive = true
}

output "elasticsearch_service_host" {
  value     = kubernetes_service.elasticsearch_service.metadata[0].name
  sensitive = true
}

output "rabbitmq_service_host" {
  value = kubernetes_service.rabbitmq_service.metadata[0].name
}

output "rabbitmq_service_amqp_port" {
  value = kubernetes_service.rabbitmq_service.spec[0].port[0].node_port
}
