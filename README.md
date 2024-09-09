# Deploy ArgoCD and Rancher In a New AWS EKS Cluster
The repo contains code that deploys and AWS EKS cluster using the common EKS terraform module while also leveraging the common terraform VPC module to deploy rhe required VPC and subnets with network tags.
In addition, we are deploying both ArgoCD and Rancher using the helm provider for terraform, both system are production ready with HA and external DB for Rancher.

## EKS-Infra
The EKS-Infra file conatins the code for the AWS EKS and network settings, the deployment create a manged node group with the minimum of 3 nodes.
ArgoCD requires a minimum of 3 worker nodes for the HA (High Availability) deployment.

## ArgoCD
The ArgoCD terraform file is responcible for the deployment of the service using the helm provider, the deployments take care of a few espects: AWS NLB with SSL, Okta integration, High Availability.
Before you deploy argo you will need to go to the okta admin portal and create a new app integration for the deployment, since the public endpoint is deployed after the app integration is created you should use the URL
you intended to use and create a DNS CNAME record in your DNS service provider.

## Rancher
The Rancher terraform file does the same as the ArgoCD, deploy's Rancher with AWS NLB, Okta Integration, High Availability but it will also use AWS RDS as the external database.

## RDS-Cluster
Deploys a RDS instance with a replica in another region, the code is configured to have scheduled maintenance and backup cycles.
