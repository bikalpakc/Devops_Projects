
# Deployment of 3-Tier/Micro-services Web Application on AWS ECS using Fargate and Dockerhub





## Deploying 3 Tier Web Application

Step 1: Create an ECS cluster.

Step 2: Create Database in RDS (optional).

Step 3: Create repo in DockerHub.

Step 4: Create Backend docker image from Dockerfile and push to DocckerHub.

Step 5: Create an ECS task definitions for Backend.

Step 6: Create an ECS service for Backend and grab load-balancer url.

Step 7: Create Frontend docker image (using backend load-balancer url) and push to DockerHub repo.

Step 8: Create an ECS task definitions for Frontend.

Step 9: Create an ECS service for Frontend and test the Application using Front End load-balancer url.

## In case of deploying microservices backend,

Step 1:
First write docker file for each micro service in it's respective folder.

Step 2:
Create docker images for all using a docker-compose file.

Step 3:
Create a repo in ECR/Dockerhub and push all images there.

Step 4:
Create a ECS cluster and create service/task definitions for each micro-service using their particular image uploaded to dockerhub/ECR.

Step 5:
Grab the load-balancer url and either replace it in the main backend or replace using environment varaibles in dockerfile of main backend service.

Step 6:
Create docker image for main backend service (where all micro-services communicate) and deploy it in the same ECS cluster by creating a new service/task definition.

Step 7:
Now, your backend service is live on the internet. Grab the load balancer url of the main backend and use it in front end applications.

Note:
While writing CI/CD pipeline, we can update only one folder in which the change is made. That means, if any change is made and pushed in certain micro service then, the docker image for that particular micro-service can be rebuild without affecting other microservices and service/task definition of only that particular microservice will be restarted in ECS cluster.

Additional Info:
We could also deploy using docker-compose file easily, but that violates the use of microservice architecture as change in one micro-serivce results in re-build of images for all micro-services.





## Author

- [Bikalpa KC](https://www.github.com/bikalpakc)


