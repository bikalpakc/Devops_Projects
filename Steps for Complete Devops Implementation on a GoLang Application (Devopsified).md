
# Steps for Complete Devops Implementation on a GoLang Application (Devopsified)





## Steps:

1. Clone the project from GitHub and run locally, to test and understand the application (its execution, port numbers and dependencies).

2. Write/Create a Docker file(multi-stage to reduce size) and build it. Then, run it to test and access it on the web browser.

- Sample Docker File for a Go-lang application:

```bash
# ---- 1st Stage: Build the Go application ----
FROM golang:1.22.5 AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy go.mod and go.sum first (for dependency caching)
COPY go.mod ./

# Download dependencies
RUN go mod download

# Copy the rest of the application
COPY . .

# Build the Go application
RUN go build -o main .

# ---- 2nd Stage: Create a minimal runtime image ----
FROM gcr.io/distroless/base

# Set the working directory inside the container
WORKDIR /app

# Copy only the compiled binary from the previous stage
COPY --from=builder /app/main .

# Copy the static files from the previous stage
COPY --from=builder /app/static ./static

# Expose the application port
EXPOSE 8080

# Run the application
CMD ["./main"]

```
Build the docker image using : `docker build -t my-go-app-docker-image .`

Run the docker image/container using : `docker run -p 8080:8080 my-go-app-docker-image`

3. Push the image to DockerHub.

```bash
docker tag my-go-app-docker-image your-dockerhub-username/my-go-app-docker-image
docker push your-dockerhub-username/my-go-app-docker-image
```

4. Create Kubernetes manifest files like deployment.yaml, service.yaml and ingress.yaml (generally saved inside `k8s/manifests` folder).

- Sample `deployment.yaml` file
```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-go-app
  labels:
    app: my-go-app
spec:
  replicas: 1  # Number of pods
  selector:
    matchLabels:
      app: my-go-app
  template:
    metadata:
      labels:
        app: my-go-app
    spec:
      containers:
        - name: my-go-app
          image: bikalpakc/my-go-app-docker-image:v1  # Replace with your actual Docker Hub image
          ports:
            - containerPort: 8080  # Port inside the container
```

- Sample `service.yaml` file:
```bash
apiVersion: v1
kind: Service
metadata:
  name: my-go-app-service
spec:
  selector:
    app: my-go-app
  ports:
    - protocol: TCP
      port: 80         # Service port
      targetPort: 8080 # Container port
  type: ClusterIP  # Change to "LoadBalancer" to expose externally
```

- Sample `ingress.yaml` file:
```bash
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-go-app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx  # Use the NGINX Ingress Controller
  rules:
    - host: myapp.local  # Replace with your actual domain or local hostname
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-go-app-service  # Name of the Kubernetes service
                port:
                  number: 80  # Service port
```

5. Create an EKS Cluster/(Minikube cluster for local practice) with the following command:

```bash
eksctl create cluster --name demo-cluster --region us-east-1 
```

6. Apply the manifests(deployment,service and ingress) to the created EKS cluster.

- Deployment:
    ```bash
    kubectl apply -f k8s/manifests/deployment.yaml
    ```
    To check: `kubectl get pods`

- Service:
    ```bash
    kubectl apply -f k8s/manifests/service.yaml
    ```
    To check: `kubectl get services` or `kubectl get svc`

- Ingress Resource:
    ```bash
    kubectl apply -f k8s/manifests/ingress.yaml
    ```
    To check: `kubectl get ing`


7. First, try to access locally for testing by changing default “ClusterIP” to “NodePort” using the below command:
```bash
Kubectl edit svc <service_name>
```      
In this case, ```service_name```=```my-go-app-service```

After this, the application can be accessed on 
```http://<Node IP address>:<Node Port>```

To get Node IP Address: 
```bash
kubectl get nodes -o wide
```

To get Node Port: 
```bash
kubectl get svc
```

8. Create a Ingress Controller which will automatically create a LoadBalancer by watching the applied Ingress Resource and automatically maps the address to the service.

In this case, to create/apply Nginx Ingress Controller, run the following command:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.1/deploy/static/provider/aws/deploy.yaml
```
This will create Nginx Ingress controller with class name ```nginx```, create a Network LoadBalancer on AWS and map Domain to service, as described in Ingress resource.

You can verify using: ```kubectl get ing```


9. Now the application will be accessible when entered the {```host``` address defined in Ingress Resource} on web browser. But before that, Ofcourse we will have to do DNS mapping by the following ways:

- Run the command : ```nslookup <address>```
- Copy the IP address.
- Edit the hosts file by: ```sudo vim etc/hosts/```
- Add the following line: ```<obtained-ip-address> <host address specified in Ingress Resource file>```

Now the application is accessible on the ```http://<host address specified in Ingress Resource File>```

In development, we mapped DNS locally. But in production, we do differently. There will be all the sites on internet and their domains and we will have to enter/register our website/domain in the list.


10. Create Helm chart that contains all the kubernetes manifests (deployment.yaml, service.yaml, ingress.yaml) for portability and later we will make changes in the Helm chart during CI process and CD will look in the same helm for change and will apply it.

With the help of helm we can deploy all the kubernetes manifests with a single command. 

In this case : 
```bash
helm install go-web-app ./go-web-app-chart
```
To uninstall: 
```bash
helm uninstall go-web-app
```

Process:

- Make sure the helm is installed.

- Create helm chart with the following command: ```helm create go-web-app-chart```

- Copy the kubernetes manifests inside the ```helm/go-web-app-chart/templates``` folder

Helm also helps us to variablize our kubernetes manifests.
For example, in this case we replace the line in ```deployment.yaml``` inside helm templates:

```image: bikalpakc/my-go-app-docker-image:v1```

with

```image: bikalpakc/my-go-app-docker-image:{{ .Values.image.tag }}```

We can set the value dynamically inside Helm ```values.yaml``` file and that value will be loaded here in ```deployment.yaml```


11. Create a Continuous Integration yaml file by creating a directory in root folder as : 
```.github/workflows/cicd.yaml```

It will execute after any change is made to the github repository. It includes stages like, build, static code analysis, pushing docker image, updating helm chart,etc.

In this case, we can have cicd.yaml file as below:
```bash
# CICD using GitHub actions

name: CI/CD

# Exclude the workflow to run on changes to the helm chart
on:
  push:
    branches:
      - main
    paths-ignore:
      - 'helm/**'
      - 'k8s/**'
      - 'README.md'

jobs:

  build:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Set up Go 1.22
      uses: actions/setup-go@v2
      with:
        go-version: 1.22

    - name: Build
      run: go build -o go-web-app

    - name: Test
      run: go test ./...
 
  code-quality:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Run golangci-lint
      uses: golangci/golangci-lint-action@v6
      with:
        version: v1.56.2
 
  push:
    runs-on: ubuntu-latest
    needs: build

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v1

    - name: Login to DockerHub
      uses: docker/login-action@v3
      with:
        username: ${{ secrets.DOCKERHUB_USERNAME }}
        password: ${{ secrets.DOCKERHUB_TOKEN }}

    - name: Build and Push action
      uses: docker/build-push-action@v6
      with:
        context: .
        file: ./Dockerfile
        push: true
        tags: ${{ secrets.DOCKERHUB_USERNAME }}/go-web-app:${{github.run_id}}

  update-newtag-in-helm-chart:
    runs-on: ubuntu-latest
    needs: push

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4
      with:
        token: ${{ secrets.TOKEN }}

    - name: Update tag in Helm chart
      run: |
        sed -i 's/tag: .*/tag: "${{github.run_id}}"/' helm/go-web-app-chart/values.yaml

    - name: Commit and push changes
      run: |
        git config --global user.email "bikalpainq@gmail.com"
        git config --global user.name "Bikalpa KC"
        git add helm/go-web-app-chart/values.yaml
        git commit -m "Update tag in Helm chart"
        git push

```

12. Final Stage i.e. Continuous Deployment.
 We configure Argo CD inside our Kubernetes cluster and if ArgoCD detects any change in the helm chart’s ```values.yaml``` file, then it will automatically synchronize the changes.

Install Argo CD using manifests with the following commands:

```bash
kubectl create namespace argocd

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
Access the ArgoCD UI, obtain the password for the login by decoding it. Then, configure to monitor the helm chart.





## Acknowledgements

 - [Youtube video by Abhishek Veeramalla](https://youtu.be/HGu9sgoHaJ0?si=yXOPOWEShfXGNymu)
 - [Go-Lang Application used](https://github.com/iam-veeramalla/go-web-app)




## Technologies Used
- AWS EKS
- Kubernetes
- Docker
- Helm Chart
- Github Actions
- Argo CD

## Commonly Asked Questions
 - [ChatGPT session](https://chatgpt.com/share/683c29a9-9ea4-8011-bcf5-8022068092a8)



## Author

- [Bikalpa KC](https://www.github.com/bikalpakc)


