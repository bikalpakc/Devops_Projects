
# Steps to Deploy an E Commerce Three Tier application on AWS EKS 





## Steps:

1. Install the following Pre-requisites: 
- AWS CLI
- Kubectl
- EKSctl

2. Create an EKS cluster with the command:
```bash
eksctl create cluster --name demo-cluster-three-tier-1 --region us-east-1
```
Later, you can delete the cluster with the command:
```bash
eksctl delete cluster --name demo-cluster-three-tier-1 --region us-east-1
```

3. (OIDC Configuration) Link OIDC connector to the EKS cluster, so that you can integrate IAM Roles into your EKS cluster and after that, EKS cluster will able to communicate with other AWS Services like EBS for data storage, based on permission/roles provided in attached IAM Role.

So, first export the cluster name with the command:
```export cluster_name=<CLUSTER-NAME>```

This command stores the value of ```<CLUSTER-NAME>``` in a shell environment variable named ```cluster_name```, so that you can use it within the same terminal session in your future CLI commands. Like, it is used in the below command.

Then, Get/export/store the OIDC id with the following command:
```bash
oidc_id=$(aws eks describe-cluster --name $cluster_name --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
``` 

Now, check if there is an IAM OIDC provider configured already with the below command:
```bash
aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4
```

If not, configure the OIDC provider by running the below command:
```bash
eksctl utils associate-iam-oidc-provider --cluster $cluster_name --approve
```


3. Configure Application Load Balancer (ALB), so that the application can be accessed on the Internet (external world). ALB(Ingress controller) will look look into the Ingress resource and redirect/handle request accordingly. Ingress defines what service to run when which URL is entered. Service consists of deployment/pods.

	Download IAM policy:
```bash
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.11.0/docs/install/iam_policy.json
```

Create IAM Policy:
```bash
aws iam create-policy \
--policy-name AWSLoadBalancerControllerIAMPolicy \
--policy-document file://iam_policy.json
```

Create IAM Role:
```bash
eksctl create iamserviceaccount \
--cluster=<your-cluster-name> \
--namespace=kube-system \
--name=aws-load-balancer-controller \
--role-name AmazonEKSLoadBalancerControllerRole \
--attach-policy-arn=arn:aws:iam::<your-aws-account-id>:policy/AWSLoadBalancerControllerIAMPolicy \
--approve
```

Deploy ALB controller using the Helm chart. Add helm repo by the following command:
```bash
helm repo add eks https://aws.github.io/eks-charts
```

Update the repo:
```bash
helm repo update eks
```

Install ALB controller (i.e. get ALB controller deployment/pods up and running using the helm chart we downloaded and updated):

```bash
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=<your-cluster-name> --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller --set region=<region> --set vpcId=<your-vpc-id>
```

Verify that the deployments/pods are running:
```bash
kubectl get deployment -n kube-system aws-load-balancer-controller
```

Note: It may take some time for deployments/pods to start and get running.


4. If we want to use/communicate with EBS volume from our EKS cluster then, we should configure/add a CSI plugin. We do it by the following way:

EBS CSI Plugin configuration: The Amazon EBS CSI plugin requires IAM permissions to make calls to AWS APIs on your behalf.

Create an IAM role and attach a policy. AWS maintains an AWS managed policy or you can create your own custom policy. You can create an IAM role and attach the AWS managed policy with the following command. Replace my-cluster with the name of your cluster. The command deploys an AWS CloudFormation stack that creates an IAM role and attaches the IAM policy to it.

```bash
eksctl create iamserviceaccount \
    --name ebs-csi-controller-sa \
    --namespace kube-system \
    --cluster <YOUR-CLUSTER-NAME> \
    --role-name AmazonEKS_EBS_CSI_DriverRole \
    --role-only \
    --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
    --approve
```

Then, Run the following command. Replace with the name of your cluster, with your account ID:
```bash
eksctl create addon --name aws-ebs-csi-driver --cluster <YOUR-CLUSTER-NAME> --service-account-role-arn arn:aws:iam::<AWS-ACCOUNT-ID>:role/AmazonEKS_EBS_CSI_DriverRole --force
```

Note: If your cluster is in the AWS GovCloud (US-East) or AWS GovCloud (US-West) AWS Regions, then replace ```arn:aws:``` with ```arn:aws-us-gov:```.

References: https://repost.aws/knowledge-center/eks-persistent-storage


7. Create Helm chart for your project/repository and deploy it by creating a namespace.
Here, we are creating one single helm chart for all 12 different micro services. But, Ideally we create helm charts individually for each micro service and deploy individually. Plus, the CI/CD pipeline is also created individually for each micro service.

```bash
$ kubectl create ns robot-shop
$ helm install robot-shop --namespace robot-shop .
```

8. Now, the services/deployments/pods are up and running. Our Ingress controller ALB is also running. But, we have not created the Ingress Resource yet. So, we can create and deploy the ingress resource as below:

- ingress.yaml:
```bash
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  namespace: robot-shop
  name: robot-shop
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web
                port:
                  number: 8080
```

Deploy/Apply the above ingress resource/file with the command: 
```bash
kubectl apply -f ingress.yaml
```


9. Look at the status of Load Balancer in AWS web interface, and once it turns to active, your website will be live on the internet. And URL can also be found in the same AWS web interface or according to the path/url you set in the ```ingress.yaml``` file.




## Acknowledgements

 - [Youtube video by Abhishek Veeramalla](https://youtu.be/8T0UnSgywzY?si=RulnDHAkXdYNB5V6)
 - [Three tier web application used (Robot Shop)](https://github.com/iam-veeramalla/three-tier-architecture-demo)




## Technologies Used
- AWS EKS
- Kubernetes
- Docker
- Helm Chart
- EBS volume



## Author

- [Bikalpa KC](https://www.github.com/bikalpakc)


