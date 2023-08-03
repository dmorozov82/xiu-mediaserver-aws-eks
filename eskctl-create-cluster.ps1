# Powershell to deploy test cluster:

eksctl create cluster `
  --name k8s-cluster `
  --node-type t2.micro `
  --nodes 3 `
  --nodes-min 3 `
  --nodes-max 5 `
  --region us-west-1

# Delete cluster:

eksctl delete cluster --name k8s-cluster --region us-west-1