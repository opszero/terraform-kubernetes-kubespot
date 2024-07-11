resource "helm_release" "metrics-server" {
  depends_on = [aws_eks_cluster.cluster]
  name             = "metrics-server"
  repository       = "https://kubernetes-sigs.github.io/metrics-server/"
  chart            = "metrics-server"
  namespace        = "metrics-server"
  create_namespace = true
  version          = var.metrics_server_version
  wait             = false
  values = [<<EOF
apiService:
  create: true
EOF
  ]
}