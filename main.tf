data "kustomization_overlay" "resources" {
  resources = [
    "${path.module}/all"
  ]
  kustomize_options = {
    load_restrictor = "none"
  }
  patches {
    target = {
      kind = "Alertmanager"
      name = "prometheus-kube-prometheus-alertmanager"
    }
    patch = <<-EOF
    - op: replace
      path: /spec/externalUrl
      value: "https://alertmanager.${var.domain}/"
    EOF
  }
  patches {
    target = {
      kind = "Ingress"
      name = "prometheus-kube-prometheus-alertmanager"
    }
    patch = <<-EOF
    - op: replace
      path: /spec/rules/0/host
      value: alertmanager.${var.domain}
    EOF
  }
  patches {
    target = {
      kind = "Ingress"
      name = "prometheus-kube-prometheus-prometheus"
    }
    patch = <<-EOF
    - op: replace
      path: /spec/rules/0/host
      value: prometheus.${var.domain}
    EOF
  }
  patches {
    target = {
      kind = "Prometheus"
      name = "prometheus-kube-prometheus-alertmanager"
    }
    patch = <<-EOF
    - op: replace
      path: /spec/externalUrl
      value: "https://prometheus.${var.domain}/"
    EOF
  }
}

# first loop through resources in ids_prio[0]
resource "kustomization_resource" "p0" {
  for_each = data.kustomization_overlay.resources.ids_prio[0]
  manifest = data.kustomization_overlay.resources.manifests[each.value]
}

# then loop through resources in ids_prio[1]
# and set an explicit depends_on on kustomization_resource.p0
resource "kustomization_resource" "p1" {
  for_each   = data.kustomization_overlay.resources.ids_prio[1]
  manifest   = data.kustomization_overlay.resources.manifests[each.value]
  depends_on = [kustomization_resource.p0]
}

# finally, loop through resources in ids_prio[2]
# and set an explicit depends_on on kustomization_resource.p1
resource "kustomization_resource" "p2" {
  for_each   = data.kustomization_overlay.resources.ids_prio[2]
  manifest   = data.kustomization_overlay.resources.manifests[each.value]
  depends_on = [kustomization_resource.p1]
}
