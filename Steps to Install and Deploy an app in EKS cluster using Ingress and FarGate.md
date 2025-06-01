
# Steps to Install and Deploy an app in EKS cluster using Ingress and FarGate

Fargate configures the VPC and public/private subnets automatically for us.

We can manually deploy our app in Kubernetes by making some EC2 instances a control plane/node and some as worker plane/nodes and linking them. This is a great overhead and extra headache to fix the issues that may arise for Devops engineers. But since, AWS EKS manages these all for us, it becomes easy. We can initially configure using KOps and other tools but later if something wrong happens it is a great hassle to solve it. So, we prefer AWS EKS.



## Steps:

1. Install prerequisites : Kubectl, EKSctl and AWSCLI.

2. Connect/Configure your AWS account to the terminal.

```bash
  aws configure
```

3. Create EKS cluster using UI or CLI with the command:

```bash
  eksctl create cluster --name demo-cluster --region us-east-1 --fargate
```
Later, to delete the cluster:
```bash
eksctl delete cluster --name demo-cluster --region us-east-1
```

4. Connect to the created EKS cluster with the command:

```bash
  aws eks update-kubeconfig --name your-cluster-name –region us-east-1
```

It updates your local kubeconfig file to allow kubectl to interact with the specified EKS cluster. Then, you can view the pods, nodes, services, deployments, etc using commands like:
`Kubectl get nodes`, `kubectl get pods`, `kubectl get svc`, etc.


5. Create Fargate profile, so that you can create different namespaces, allocate certain designated memory to each namespace, etc. Basically, so that you can manage applications/services properly. Use the following command:

```bash
  eksctl create fargateprofile \
    --cluster demo-cluster \
    --region us-east-1 \
    --name alb-sample-app \
    --namespace game-2048
```

6. Now, deploy the app in the namespace of your choice with the following command:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/examples/2048/2048_full.yaml

```
Every component: pods, deployments, services, ingress is created with this same file cause everything is written in a single file. Of Course, you can individually write it and apply it individually.

7. Associate IAM OIDC Provider using the command below:

```bash
  eksctl utils associate-iam-oidc-provider --cluster $cluster_name --approve
```

8. Download IAM policy

```bash
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.11.0/docs/install/iam_policy.json
```
Downloads the required IAM policy JSON file from the GitHub repository to your local system. This file defines the permissions needed by the ALB controller.

9. Create IAM Policy

```bash
  aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json
```
Creates a new IAM policy in your AWS account using the downloaded JSON file and names it `AWSLoadBalancerControllerIAMPolicy`.

10. Create IAM Role (Service Account)

```bash
eksctl create iamserviceaccount \
  --cluster=<your-cluster-name> \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::<your-aws-account-id>:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve
```
- Creates an IAM role and a Kubernetes service account named `aws-load-balancer-controller` in the kube-system namespace of your EKS cluster.
- Attaches the IAM policy created earlier so the controller can access AWS resources.

11. Deploy ALB controller:
- Add helm repo: Adds the AWS EKS charts repository to Helm so you can install AWS-supported Helm charts like the ALB controller.
```bash
helm repo add eks https://aws.github.io/eks-charts
```


- Update the repo: Refreshes the list of charts in the Helm repo to get the latest version of the ALB controller.
```bash
helm repo update eks
```
- Install: Installs the ALB controller into the `kube-system` namespace using Helm.
```bash
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \            
  -n kube-system \
  --set clusterName=<your-cluster-name> \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=<region> \
  --set vpcId=<your-vpc-id>
```

`serviceAccount.create=false`: Reuses the service account you created earlier via `eksctl`.

`vpcId`: Needed so the ALB knows which VPC to operate in.

- Verify that the deployments are running: Verifies that the ALB controller deployment is running successfully in the `kube-system` namespace.

```bash
kubectl get deployment -n kube-system aws-load-balancer-controller
```



## Acknowledgements

 - [Youtube video by Abhishek Veeramalla](https://youtu.be/RRCrY12VY_s?si=dOQgmrWRyj9JYd6G)
 - [Used YAML file with all Deployments, Services and Ingress](https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/examples/2048/2048_full.yaml)




## Technologies Used
- AWS EKS
- Kubernetes Cluster
- AWS Fargate
- IAM Role (Service Account)

## Commonly Asked Questions
 - [ChatGPT session](https://chatgpt.com/share/683a8726-de00-8011-98f7-48e959367b89)



## Author

- [Bikalpa KC](https://www.github.com/bikalpakc)


