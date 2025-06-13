
# Complete DevOps Implementation on MERN Stack application | Steps for End to End DevOps Project (Devopsified 2)


![3-tier-gif](https://github.com/user-attachments/assets/c7d53db0-c9ab-48a2-acd4-f0403790845f)


## Steps:

1. Create a Jenkins server (EC2 instance) where, we will setup our CI/CD pipeline.

EC2, ```large``` instance can be used as we will install many different things.

Launch the EC2 instance with Administrative Access/follow least privilege rule (IAM Role) and ibound traffic rules configured for the ports that we will be using.

Launch the EC2 instance with Jenkins, Docker, Sonarqube, AWS CLI, KubeCTL, EKSCTL, Terraform, Trivy,  and Helm pre/auto installed by applying the below script during instance creation on UI. Or, you can also install these things manually later on after the instance is created.

```bash
#!/bin/bash
# For Ubuntu 22.04
# Intsalling Java
sudo apt update -y
sudo apt install openjdk-17-jre -y
sudo apt install openjdk-17-jdk -y
java --version

# Installing Jenkins
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y
sudo apt-get install jenkins -y

# Installing Docker 
#!/bin/bash
sudo apt update
sudo apt install docker.io -y
sudo usermod -aG docker jenkins
sudo usermod -aG docker ubuntu
sudo systemctl restart docker
sudo chmod 777 /var/run/docker.sock

# If you don't want to install Jenkins, you can create a container of Jenkins
# docker run -d -p 8080:8080 -p 50000:50000 --name jenkins-container jenkins/jenkins:lts

# Run Docker Container of Sonarqube
#!/bin/bash
docker run -d  --name sonar -p 9000:9000 sonarqube:lts-community

# Installing AWS CLI
#!/bin/bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip -y
unzip awscliv2.zip
sudo ./aws/install

# Installing Kubectl
#!/bin/bash
sudo apt update
sudo apt install curl -y
sudo curl -LO "https://dl.k8s.io/release/v1.28.4/bin/linux/amd64/kubectl"
sudo chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client

# Installing eksctl
#! /bin/bash
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version

# Installing Terraform
#!/bin/bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt install terraform -y

# Installing Trivy
#!/bin/bash
sudo apt-get install wget apt-transport-https gnupg lsb-release -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt update
sudo apt install trivy -y

# Intalling Helm
#! /bin/bash
sudo snap install helm --classic
```


2. Login to Jenkins on ```http://<publicIP>:8080```, setup user account and install the suggested and required plugins.

Extra plugins that we need to install manually:-
- ```AWS Credentials```: to store AWS credentials.
 
- ```Pipeline: AWS Steps```: To interact with AWS APIs.


3. Store the AWS credentials that you will need. Refer to ```31:17``` of the video for reference.


4. Install Terraform plugin and configure/set it in ```Dashboard> Manage Jenkins> Tools```
I.e. give the tool name and path (Terraform’s path in the EC2 instance)

5. Setup Jenkins pipeline to execute the Terraform code i.e. to plan(plan is set as default action, but ofcourse you can also set create as default) infrastructures required.
In this case, a sample Jenkins script/code can be as below:

```bash
properties([
    parameters([
        string(
            defaultValue: 'dev',
            name: 'Environment'
        ),
        choice(
            choices: ['plan', 'apply', 'destroy'], 
            name: 'Terraform_Action'
        )])
])
pipeline {
    agent any
    stages {
        stage('Preparing') {
            steps {
                sh 'echo Preparing'
            }
        }
        stage('Git Pulling') {
            steps {
                git branch: 'master', url: 'https://github.com/AmanPathak-DevOps/EKS-Terraform-GitHub-Actions.git'
            }
        }
        stage('Init') {
            steps {
                withAWS(credentials: 'aws-creds', region: 'us-east-1') {
                sh 'terraform -chdir=eks/ init'
                }
            }
        }
        stage('Validate') {
            steps {
                withAWS(credentials: 'aws-creds', region: 'us-east-1') {
                sh 'terraform -chdir=eks/ validate'
                }
            }
        }
        stage('Action') {
            steps {
                withAWS(credentials: 'aws-creds', region: 'us-east-1') {
                    script {    
                        if (params.Terraform_Action == 'plan') {
                            sh "terraform -chdir=eks/ plan -var-file=${params.Environment}.tfvars"
                        }   else if (params.Terraform_Action == 'apply') {
                            sh "terraform -chdir=eks/ apply -var-file=${params.Environment}.tfvars -auto-approve"
                        }   else if (params.Terraform_Action == 'destroy') {
                            sh "terraform -chdir=eks/ destroy -var-file=${params.Environment}.tfvars -auto-approve"
                        } else {
                            error "Invalid value for Terraform_Action: ${params.Terraform_Action}"
                        }
                    }
                }
            }
        }
    }
}
```

6. Install ```Pipeline: Stage View``` plugin for better visibility and run the pipeline. The AWS infrastructures will be planned(you can also configure Jenkins file to directly create the resource).

Note: You should have the terraform files written in the github directory mentioned in the above Jenkins script.


7. Click on ```Build with Parameters``` on Jenkins pipeline interface, select the environment (```dev``` is set in our case in Jenkins file/script) and set the ```terraform_action``` to ```apply``` and click on the ```Build``` button.

Now, our VPC, EKS cluster and every infrastructure will start creating. It will take some time. The infrastructure would look as below:

![Screenshot 2025-06-12 174855](https://github.com/user-attachments/assets/c901f8f8-3f57-4816-b974-bbac9673e5df)



8. Meanwhile, we can create a ```JUMP Server``` in the VPC that we just created. Our EKS cluster is inside a private VPC, and we cannot access it directly from outside due to security reasons. So, we will provide the access to JUMP server, which is also inside the private VPC and the JUMP server can communicate with the EKS cluster as they are in the same VPC. So, we will communicate with EKS cluster via JUMP server.

We create Jump server by launching a ```t2.medium``` type EC2 instance from UI on the new VPC created by Terraform through Jenkins server and on a public subnet with 30 GB storage and administrative access/permissions/roles. 

Also, we need to setup the below things in our Jump server:

- AWS CLI
- KubeCTL
- Helm
- EKSCTL

We can run the below script while starting an EC2 instance:
```bash
--Write yourself or ask chatgpt to generate it for you--
```

Check if you can communicate with the EKS cluster from Jump server. In Jump server, run the commands like:

```aws eks update-kubeconfig –dev-medium-eks-cluster –region us-east-1```

```kubectl get nodes```

Refer to ```48:25``` on the video.



9. Configure Application Load Balancer. 
For that, First Download and install the below policy, so that we can later attach it to the service account of pods/eks..so that EKS can create and communicate with other AWS services like ALB controller(Load Balancer)

Download the policy for the LoadBalancer prerequisite:
```bash
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json
```

Create the IAM policy using the below command:
```bash
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json
```

Associate OIDC Provider:
```bash
eksctl utils associate-iam-oidc-provider --region=us-east-1 --cluster=Three-Tier-K8s-EKS-Cluster --approve
```

Create a Service Account/IAM Role by using below command and replace your account ID with your one:
```bash
eksctl create iamserviceaccount --cluster=Three-Tier-K8s-EKS-Cluster --namespace=kube-system --name=aws-load-balancer-controller --role-name AmazonEKSLoadBalancerControllerRole --attach-policy-arn=arn:aws:iam::<your_account_id>:policy/AWSLoadBalancerControllerIAMPolicy --approve --region=us-east-1
```

Run the below command to deploy the AWS Load Balancer Controller:
```bash
sudo snap install helm --classic
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=my-cluster --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller
```

After 2 minutes, run the command below to check whether your pods are running or not:
```bash
kubectl get deployment -n kube-system aws-load-balancer-controller
```

If the pods are getting Error or CrashLoopBackOff, then use the below command:
```bash
helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
  --set clusterName=<cluster-name> \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=us-west-1 --set vpcId=<vpc#> -n kube-system
```

10. Install & Configure ArgoCD
First, create a namespace for ArgoCD:
```bash
kubectl create namespace argocd
```

Run the below command. This will install and create all the resources related to ArgoCD:
```bash
Kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.4.7/manifests/install.yaml
```

Now, check if everything is up and running:
```bash
Kubectl get all -n argocd
```

Currently ArgoCD service is running in ```ClusterIP``` mode by default, we change it to ```NodePort``` or ```Load balancer``` inorder to access from the browser or outside world. For that, we need to edit and change it in the service file:

```bash
Kubectl get svc -n argocd  //To see all the running services in the “argocd” namespace
Kubectl edit svc argocd-server -n argocd    //to edit the service
```

Now, After saving the service file, a load balancer will be created by “Cloud Control Manager” component of EKS.

Go to the Load Balancers section in the AWS UI in browser to get the dns address for the loadbalancer to access the ArgoCD user interface.

Default username: ```admin```
Get password by the following method/commands:
```bash
Kubectl get secrets -n argocd    //to see all the secrets
Kubectl edit secret argocd-initial-admin-secret -n argocd  //to see the default password
```

Copy the password and decode it with the help of base64:
```bash
echo <password you copied> | base64 --decode
```

And then, you will get the real password to log into ArgoCD.

11. Login to ArgoCD using the credentials obtained.

12. Now configure Sonarqube. We have already installed it on our jenkins server. So, set it running if not and access it in the address:

```http://<instance-public-ip>:9000```

Default username: ```admin```

Default password: ```admin```

13. Connect Jenkins with sonarqube (allow communication) by generating a Sonarqube token and configuring a web hook for Jenkins server. Refer to ```1:25:46``` to generate a token and integrate Sonarqube with Jenkins.

14. Create a project on Sonarqube for the project/code base that you want the static code analysis for.

For example, if you create a project for front end on Sonarqube, then Sonarqube will do the static code analysis for the frontend code.

15. Copy the Sonarqube generated code and later we paste it inside a pipeline script to authenticate Sonarqube, in ```step 21```.

16. Store the Sonarqube credentials on Jenkins as a ```secret file```, where secret = Sonarqube Token that we generated.

You can also store your AWS account ID.

Also store your github personal access token as credential as we will have to communicate and read/write to our github repository to fetch and edit images and stuffs.

17. Create private ECR(Elastic Container Register, just like Dockerhub but provided by Amazon) repositories, “frontend” and “backend” to store your frontend and backend docker images. Refer to ```1:32:00```
	
Also store these values “frontend” and “backend” as secrets in Jenkins for id smthg like ```ECR Repo1``` and ```ECR Repo2```. So, that our ECR repositories remain anonymous for intruders.

18. Install some more plugins for the Jenkins CI/CD pipeline. They include:
- Docker
- Docker Commons
- Docker Pipeline
- Docker API
- Nodejs (as the web app we are deploying is a Nodejs project)
- Owasp Dependency-Check(it will check the dependencies)
- Sonarqube Scanner

19. Now configure the tools/plugins we installed like we did earlier for Terraform by going to
```Dashboard> Manage Jenkins> Tools```
i.e. give the tool name and path (E.g. Terraform’s path in the EC2 instance)

Refer to ```1:38:11``` in the video.

20. Configure the webhook for Sonarqube quality gate (sonar-server, we already did for sonarqube-scanner for code quality analysis). Refer to ```1:40:12``` timestamp on the video.

21. Everything is done now. We need to create pipeline for our project/microservices. In our case two pipelines for frontend and backend. Also fill the Sonarqube generated code/metrics in Jenkins pipeline script, that we got/copied in ```Step 15```.

The Front end pipeline can be constructed from the following Jenkins pipeline :
```bash
pipeline {
    agent any 
    tools {
        nodejs 'nodejs'
    }
    environment  {
        SCANNER_HOME=tool 'sonar-scanner'
        AWS_ACCOUNT_ID = credentials('ACCOUNT_ID')
        AWS_ECR_REPO_NAME = credentials('ECR_REPO1')
        AWS_DEFAULT_REGION = 'us-east-1'
        REPOSITORY_URI = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/"
    }
    stages {
        stage('Cleaning Workspace') {
            steps {
                cleanWs()
            }
        }
        stage('Checkout from Git') {
            steps {
                git credentialsId: 'GITHUB', url: 'https://github.com/AmanPathak-DevOps/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project.git'
            }
        }
        stage('Sonarqube Analysis') {
            steps {
                dir('Application-Code/frontend') {
                    withSonarQubeEnv('sonar-server') {
                        sh ''' $SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectName=three-tier-frontend \
                        -Dsonar.projectKey=three-tier-frontend '''
                    }
                }
            }
        }
        stage('Quality Check') {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token' 
                }
            }
        }
        stage('OWASP Dependency-Check Scan') {
            steps {
                dir('Application-Code/frontend') {
                    dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                    dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
                }
            }
        }
        stage('Trivy File Scan') {
            steps {
                dir('Application-Code/frontend') {
                    sh 'trivy fs . > trivyfs.txt'
                }
            }
        }
        stage("Docker Image Build") {
            steps {
                script {
                    dir('Application-Code/frontend') {
                            sh 'docker system prune -f'
                            sh 'docker container prune -f'
                            sh 'docker build -t ${AWS_ECR_REPO_NAME} .'
                    }
                }
            }
        }
        stage("ECR Image Pushing") {
            steps {
                script {
                        sh 'aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${REPOSITORY_URI}'
                        sh 'docker tag ${AWS_ECR_REPO_NAME} ${REPOSITORY_URI}${AWS_ECR_REPO_NAME}:${BUILD_NUMBER}'
                        sh 'docker push ${REPOSITORY_URI}${AWS_ECR_REPO_NAME}:${BUILD_NUMBER}'
                }
            }
        }
        stage("TRIVY Image Scan") {
            steps {
                sh 'trivy image ${REPOSITORY_URI}${AWS_ECR_REPO_NAME}:${BUILD_NUMBER} > trivyimage.txt' 
            }
        }
        stage('Checkout Code') {
            steps {
                git credentialsId: 'GITHUB', url: 'https://github.com/AmanPathak-DevOps/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project.git'
            }
        }
        stage('Update Deployment file') {
            environment {
                GIT_REPO_NAME = "End-to-End-Kubernetes-Three-Tier-DevSecOps-Project"
                GIT_USER_NAME = "AmanPathak-DevOps"
            }
            steps {
                dir('Kubernetes-Manifests-file/Frontend') {
                    withCredentials([string(credentialsId: 'github', variable: 'GITHUB_TOKEN')]) {
                        sh '''
                            git config user.email "aman07pathak@gmail.com"
                            git config user.name "AmanPathak-DevOps"
                            BUILD_NUMBER=${BUILD_NUMBER}
                            echo $BUILD_NUMBER
                            imageTag=$(grep -oP '(?<=frontend:)[^ ]+' deployment.yaml)
                            echo $imageTag
                            sed -i "s/${AWS_ECR_REPO_NAME}:${imageTag}/${AWS_ECR_REPO_NAME}:${BUILD_NUMBER}/" deployment.yaml
                            git add deployment.yaml
                            git commit -m "Update deployment Image to version \${BUILD_NUMBER}"
                            git push https://${GITHUB_TOKEN}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME} HEAD:master
                        '''
                    }
                }
            }
        }
    }
}
```


22. After the pipeline is executed, it can also be seen in Sonarqube server.

Execute the pipeline also for the backend using the following Jenkins script:

```bash
pipeline {
    agent any 
    tools {
        nodejs 'nodejs'
    }
    environment  {
        SCANNER_HOME=tool 'sonar-scanner'
        AWS_ACCOUNT_ID = credentials('ACCOUNT_ID')
        AWS_ECR_REPO_NAME = credentials('ECR_REPO2')
        AWS_DEFAULT_REGION = 'us-east-1'
        REPOSITORY_URI = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/"
    }
    stages {
        stage('Cleaning Workspace') {
            steps {
                cleanWs()
            }
        }
        stage('Checkout from Git') {
            steps {
                git credentialsId: 'GITHUB', url: 'https://github.com/AmanPathak-DevOps/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project.git'
            }
        }
        stage('Sonarqube Analysis') {
            steps {
                dir('Application-Code/backend') {
                    withSonarQubeEnv('sonar-server') {
                        sh ''' $SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectName=three-tier-backend \
                        -Dsonar.projectKey=three-tier-backend '''
                    }
                }
            }
        }
        stage('Quality Check') {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token' 
                }
            }
        }
        stage('OWASP Dependency-Check Scan') {
            steps {
                dir('Application-Code/backend') {
                    dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                    dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
                }
            }
        }
        stage('Trivy File Scan') {
            steps {
                dir('Application-Code/backend') {
                    sh 'trivy fs . > trivyfs.txt'
                }
            }
        }
        stage("Docker Image Build") {
            steps {
                script {
                    dir('Application-Code/backend') {
                            sh 'docker system prune -f'
                            sh 'docker container prune -f'
                            sh 'docker build -t ${AWS_ECR_REPO_NAME} .'
                    }
                }
            }
        }
        stage("ECR Image Pushing") {
            steps {
                script {
                        sh 'aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${REPOSITORY_URI}'
                        sh 'docker tag ${AWS_ECR_REPO_NAME} ${REPOSITORY_URI}${AWS_ECR_REPO_NAME}:${BUILD_NUMBER}'
                        sh 'docker push ${REPOSITORY_URI}${AWS_ECR_REPO_NAME}:${BUILD_NUMBER}'
                }
            }
        }
        stage("TRIVY Image Scan") {
            steps {
                sh 'trivy image ${REPOSITORY_URI}${AWS_ECR_REPO_NAME}:${BUILD_NUMBER} > trivyimage.txt' 
            }
        }
        stage('Checkout Code') {
            steps {
                git credentialsId: 'GITHUB', url: 'https://github.com/AmanPathak-DevOps/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project.git'
            }
        }
        stage('Update Deployment file') {
            environment {
                GIT_REPO_NAME = "End-to-End-Kubernetes-Three-Tier-DevSecOps-Project"
                GIT_USER_NAME = "AmanPathak-DevOps"
            }
            steps {
                dir('Kubernetes-Manifests-file/Backend') {
                    withCredentials([string(credentialsId: 'github', variable: 'GITHUB_TOKEN')]) {
                        sh '''
                            git config user.email "aman07pathak@gmail.com"
                            git config user.name "AmanPathak-DevOps"
                            BUILD_NUMBER=${BUILD_NUMBER}
                            echo $BUILD_NUMBER
                            imageTag=$(grep -oP '(?<=backend:)[^ ]+' deployment.yaml)
                            echo $imageTag
                            sed -i "s/${AWS_ECR_REPO_NAME}:${imageTag}/${AWS_ECR_REPO_NAME}:${BUILD_NUMBER}/" deployment.yaml
                            git add deployment.yaml
                            git commit -m "Update deployment Image to version \${BUILD_NUMBER}"
                            git push https://${GITHUB_TOKEN}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME} HEAD:master
                        '''
                    }
                }
            }
        }
    }
}
```

23. Now, configure ArgoCD by connecting the source code repository(main), so that any changes in that repository would be tracked and deployed automatically by ArgoCD.

Then, create 3 applications in ArgoCD : 
- database
- frontend
- backend

Also, don’t forget to create namespaces in your kubernetes cluster for database, frontend and backend.

Refer to ```2:01:56``` time stamp on the video.

24. Create an ingress controller inorder to access the containers deployed inside the EKS Cluster, to make it accessible from the outside world. Refer to ```2:11:40``` on the video.
	
Also add the domain’s DNS to route53, otherwise the site/page won’t be accessible from the internet.

25. Now, the final segment is of Monitoring and Visualization using ```Prometheus``` and ```Grafana```. Refer to the segment ```2:21:08``` of the video.

Install ```Prometheus``` and ```Graphana``` on the ```JUMP server``` (using helmchart in this case), run the service, change the service type from ```ClusterIP``` to ```loadBalancer```, copy the load balancer address and access Prometheus/Graphana on browser, login, setup Prometheus to gather data, and set up Graphana to extract data from Prometheus for visualization.

Follow the below guide from ```Step 10``` incase of any confusion:
https://blog.stackademic.com/advanced-end-to-end-devsecops-kubernetes-three-tier-project-using-aws-eks-argocd-prometheus-fbbfdb956d1a















## Acknowledgements

 - [Youtube video by Abhishek Veeramalla](https://youtu.be/-AAcMNncCa4?si=zRf-eBkV1xBoCK-f)
 - [Three tier MERN stack web application used](https://github.com/AmanPathak-DevOps/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project/)
 - [Article by Aman Pathak](https://blog.stackademic.com/advanced-end-to-end-devsecops-kubernetes-three-tier-project-using-aws-eks-argocd-prometheus-fbbfdb956d1a)




## Technologies Used
- Jenkins
- Terraform
- Private VPC
- AWS EKS
- AWS ECR
- Kubernetes
- Docker
- Helm Chart
- SonarQube
- Trivy
- OWASP Dependency-Check Scan
- Prometheus
- Graphana
- ArgoCD



## Author

- [Bikalpa KC](https://www.github.com/bikalpakc)


