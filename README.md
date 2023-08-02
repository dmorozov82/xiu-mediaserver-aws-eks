# Deploy XIU on AWS EKS (Kubernetes) with AWS Load Balancer Controller
XIU rtmp-cluster https://github.com/harlanc/xiu.git

Requrements: 
- Install kubectl, awscli and eksctl tools
For Windows:
- Install Chocolatey (in pwrsh elevated mode):
https://www.studytonight.com/post/install-chocolatey-package-manager-for-windows
```
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
```
- Install Helm:
https://www.studytonight.com/post/installing-kubernetes-helm-on-windows
``` choco install kubernetes-helm ```
- In Linux replace "`" with backslash "\\" in multiline code.

# Deployment to EKS
1. Deploy k8s cluster using eksctl tool:
```
eksctl create cluster `
  --name k8s-cluster `
  --node-type t2.micro `
  --nodes 3 `
  --nodes-min 3 `
  --nodes-max 5 `
  --region us-west-1
```
2. Download an IAM policy for the AWS Load Balancer Controller that allows it to make calls to AWS APIs on your behalf:
```
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.7/docs/install/iam_policy.json
```
3. Create an IAM policy using the policy downloaded in the previous step:
```
aws iam create-policy `
    --policy-name AWSLoadBalancerControllerIAMPolicy `
    --policy-document file://iam_policy.json
```
4. Create an IAM role. Create a Kubernetes service account named aws-load-balancer-controller in the kube-system namespace for the AWS Load Balancer Controller and annotate the Kubernetes service account with the name of the IAM role (851737112717 - Account ID):
```
aws configure set region us-west-1 

eksctl utils associate-iam-oidc-provider --region=us-west-1 --cluster=k8s-cluster --approve

eksctl create iamserviceaccount `
  --cluster=k8s-cluster `
  --namespace=kube-system `
  --name=aws-load-balancer-controller `
  --role-name AmazonEKSLoadBalancerControllerRole `
  --attach-policy-arn=arn:aws:iam::851737112717:policy/AWSLoadBalancerControllerIAMPolicy `
  --approve
```
5. Install the AWS Load Balancer Controller using Helm V3 or later or by applying a Kubernetes manifest.

Add the eks-charts repository.
```
helm repo add eks https://aws.github.io/eks-charts
```
Update your local repo to make sure that you have the most recent charts.
```
helm repo update eks
```
Install the AWS Load Balancer Controller.
```
helm install aws-load-balancer-controller eks/aws-load-balancer-controller `
  -n kube-system `
  --set clusterName=k8s-cluster `
  --set serviceAccount.create=false `
  --set serviceAccount.name=aws-load-balancer-controller 
```
6. Verify that the controller is installed.
```
kubectl get deployment -n kube-system aws-load-balancer-controller
```
7. Deploy Xiu server:
```
kubectl apply -f xiu-namespace.yaml
kubectl apply -f xiu-configmap-master.yaml
kubectl apply -f xiu-deployment.yaml
kubectl apply -f xiu-service.yaml
kubectl apply -f xiu-ingress.yaml
```
8. Check the pods is alive:
```
kubectl get pods --all-namespaces
```
9. Check ingress:
```
kubectl get ingress --namespace xiu-prod-ns
NAME          CLASS   HOSTS   ADDRESS                                                                  PORTS   AGE
xiu-ingress   alb     *       k8s-xiuprodn-xiuingre-78d3c95990-455589512.us-west-1.elb.amazonaws.com   80      31m
```
10. Deploy HPA wich will scale pods when avarage CPU usage above 60%:
```
kubectl apply -f xiu-autoscaller.yaml
```
