# springboot-kong-keycloak

The goal is to create a [`Spring Boot`](https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/) application to manage books, called `book-service`. It will only be reachable through [`Kong`](https://konghq.com/kong/) API gateway. In `Kong`, we will install [`kong-oidc`](https://github.com/nokia/kong-oidc) plugin that will enable the communication between `Kong` and [`Keycloak`](https://www.keycloak.org) OpenID Connect Provider. This way, when `Kong` receives a request to `book-service`, it will validate together with `Keycloak` whether it's a valid request or not before redirecting to the upstream service.

## Project Diagram

![project-diagram](documentation/project-diagram.png)

## Application

- ### book-service

  `Spring Boot` REST API application to manages books. The API is completely open and doesn't have any security. `book-service` uses [`MongoDB`](https://www.mongodb.com) as storage.

  Endpoints
  ```
  GET /api/books
  GET /api/books/{id}
  POST /api/books {"title": "..."}
  DELETE /api/books/{id}
  GET /actuator/health
  ```

## Prerequisites

- [`Java 11+`](https://www.oracle.com/java/technologies/downloads/#java11)
- [`Docker`](https://www.docker.com/)
- [`jq`](https://stedolan.github.io/jq)

## Run application during development using Maven

- Open a terminal and navigate to `springboot-kong-keycloak` root folder

- Run the command below to start `mongodb` Docker container
  ```
  docker run -d --name mongodb -p 27017:27017 mongo:5.0.3
  ```

- Run the command below to start `book-service`
  ```
  ./mvnw clean spring-boot:run --projects book-service
  ```

- Open another terminal and call application endpoints
  ```
  curl -i http://localhost:9080/api/books
  curl -i -X POST http://localhost:9080/api/books -H "Content-Type: application/json" -d '{"title": "Kong & Keycloak"}'
  curl -i http://localhost:9080/api/books/<BOOK_ID>
  curl -i -X DELETE http://localhost:9080/api/books/<BOOK_ID>
  curl -i http://localhost:9080/actuator/health
  ```

- To stop
  - `book-service`, go to the terminal where it's running and press `Ctrl+C`
  - `mongodb` Docker container, go to a terminal and run the following command
    ```
    docker rm -fv mongodb
    ```

## Build application Docker Image

- In a terminal, make sure you are in `springboot-kong-keycloak` root folder

- Build Docker Image
  ```
  ./docker-build.sh
  ```

## Test application Docker Image

- In a terminal, create a Docker network
  ```
  docker network create springboot-kong-keycloak-net
  ```

- Run the command below to start `mongodb` Docker container
  ```
  docker run -d --name mongodb -p 27017:27017 --network springboot-kong-keycloak-net mongo:5.0.3
  ```

- Run the following command to start `book-service` Docker container
  ```
  docker run --rm -p 9080:9080 --name book-service -e MONGODB_HOST=mongodb --network springboot-kong-keycloak-net ivanfranchin/book-service:1.0.0
  ```

- Open another terminal and call application endpoints
  ```
  curl -i http://localhost:9080/api/books
  curl -i -X POST http://localhost:9080/api/books -H "Content-Type: application/json" -d '{"title": "Kong & Keycloak"}'
  curl -i http://localhost:9080/api/books/<BOOK_ID>
  curl -i -X DELETE http://localhost:9080/api/books/<BOOK_ID>
  curl -i http://localhost:9080/actuator/health
  ```

- To stop
  - `book-service`, go to the terminal where it's running and press `Ctrl+C`
  - `mongodb` Docker container, go to a terminal and run the following command
    ```
    docker rm -fv mongodb
    ```
  - remove Docker network
    ```
    docker network rm springboot-kong-keycloak-net
    ```

## Build Kong Docker Image with kong-oidc plugin

- In a terminal, make use you are in `springboot-kong-keycloak` root folder

- In order to create the image, run the command below
  ```
  docker build -t kong:2.6.0-centos-oidc docker/kong
  ```

## Start environment

- In a terminal, make use you are in `springboot-kong-keycloak` root folder

- Run the following script
  ```
  ./start-docker-containers.sh
  ```

- Wait for Docker containers to be `healthy`. To check it, run
  ```
  docker ps -a
  ```

> **Note:** `book-service` application is running as a Docker container. The container does not expose any port to HOST machine. So, it cannot be accessed directly, forcing the caller to use `Kong` as gateway server in order to access it.

## Configure Keycloak

- Open a new terminal and make sure you are in `springboot-kong-keycloak` root folder

- Run the following script to configure `Keycloak` for `book-service` application
  ```
  ./init-keycloak.sh
  ```

  This script creates the `company-services` realm, the `book-service` client and a user with _username_ `ivan.franchin` and _password_ `123`.

- The `book-service` client secret (`BOOK_SERVICE_CLIENT_SECRET`) is shown at the end of the execution. It will be used in the next step

- You can check the configuration in `Keycloak` by accessing http://localhost:8080. The credentials are `admin/admin`.

## Configure Kong

- In a terminal, make sure you are in `springboot-kong-keycloak` root folder

- Create an environment variable that contains the `Client Secret` generated by `Keycloak` to `book-service` at [Configure Keycloak](#Configure Keycloak) step
  ```
  BOOK_SERVICE_CLIENT_SECRET=...
  ```

- Create an environment variable that contains the machine IP
  ```
  HOST_IP=$(ipconfig getifaddr en0)
  ```

- In order to configure `Kong` for `book-service` application, we will use `init-kong.sh`
 
  It creates a service to `book-service`, a route to the service and add the `kong-oidc` plugin to the route.

  In the third parameter of the script, we can set the `kong-oidc` config property `bearer_only`:
    - if the value is `no`, `Kong` will redirect the user to `Keycloak` login page upon an unauthorized request;
    - if the value is `yes`, `Kong` will introspect tokens without redirecting.

  **(1) Setting `no` to `bearer_only`**
    
  - Run the following command
    ```
    ./init-kong.sh $BOOK_SERVICE_CLIENT_SECRET $HOST_IP "no"
    ```
    
  - In a browser, access http://localhost:8000/book-service/api/books
  - You will be redirected to `Keycloak` login page
  - Enter the credentials `ivan.franchin/123`
  - You should see the list of books (maybe an empty array)

  **(2) Setting "yes" (default) to `bearer_only`**

  - Run the following command
    ```
    ./init-kong.sh $BOOK_SERVICE_CLIENT_SECRET $HOST_IP
    ```

  - Try to call `GET /api/books` endpoint without access token
    ```
    curl -i http://localhost:8000/book-service/api/books
    ```

    It should return
    ```
    HTTP/1.1 401 Unauthorized
    no Authorization header found
    ```

  - Get access token by running the commands below to get an access token for `ivan.franchin`
    ```
    ACCESS_TOKEN=$(./get-access-token.sh $BOOK_SERVICE_CLIENT_SECRET $HOST_IP)
    echo $ACCESS_TOKEN
    ```

  - Call `GET /api/books` endpoint using access token
    ```
    curl -i http://localhost:8000/book-service/api/books -H 'Authorization: Bearer $ACCESS_TOKEN'
    ```

    It should return
    ```
    HTTP/1.1 200
    []
    ```
    > **Warning:** currently, it's not working. it's returning 
    > ```
    > HTTP/1.1 401 Unauthorized
    > invalid token
    > ```

## Shutdown

Go to the terminal where you run the script `start-docker-containers.sh` and press `q` to stop and remove all containers

## Cleanup

To remove the Docker image created by this project, go to a terminal and run the command below
```
docker rmi ivanfranchin/book-service:1.0.0
docker rmi kong:2.6.0-centos-oidc
```

## References

- https://www.jerney.io/secure-apis-kong-keycloak-1/
- https://github.com/d4rkstar/kong-konga-keycloak
