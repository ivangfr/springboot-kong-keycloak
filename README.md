# springboot-kong-keycloak

The goal is to create a [`Spring Boot`](https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/) application to manage books, called `book-service` and secure it by using [`Kong`](https://konghq.com/kong/) API gateway and [`Keycloak`](https://www.keycloak.org) OpenID Connect Provider.

> **Note:** In [`kubernetes-minikube-environment`](https://github.com/ivangfr/kubernetes-minikube-environment/tree/master/book-service-kong-keycloak) repository, it's shown how to deploy this project in `Kubernetes` (`Minikube`)

## Project Diagram

![project-diagram](documentation/project-diagram.png)

As we can see from the diagram, `book-service` will only be reachable through `Kong` API gateway.

In `Kong`, it's installed [`kong-oidc`](https://github.com/nokia/kong-oidc) plugin that will enable the communication between `Kong` and `Keycloak` OpenID Connect Provider.

This way, when `Kong` receives a request to `book-service`, it will validate together with `Keycloak` whether it's a valid request.

Also, before redirecting to the request to the upstream service, a `Serverless Function (post-function)` will get the access token present in the `X-Userinfo` header provided by `kong-oidc` plugin, decoded it, extracts the `username` and `preferred_username`, and enriches the request with these two information before sending to `book-service`

## Application

- ### book-service

  `Spring Boot` REST API application to manages books. The API doesn't have any security. `book-service` uses [`MongoDB`](https://www.mongodb.com) as storage.

  Endpoints
  ```
  GET /actuator/health
  GET /api/books
  POST /api/books {"isbn": "...", "title": "..."}
  GET /api/books/{isbn}
  DELETE /api/books/{isbn}
  ```

## Prerequisites

- [`Java 11+`](https://www.oracle.com/java/technologies/downloads/#java11)
- [`Docker`](https://www.docker.com/)
- [`jq`](https://stedolan.github.io/jq)

## Run application during development using Maven

- Open a terminal and navigate to `springboot-kong-keycloak` root folder

- Run the command below to start `mongodb` Docker container
  ```
  docker run -d --name mongodb -p 27017:27017 mongo:5.0.4
  ```

- Run the command below to start `book-service`
  ```
  ./mvnw clean spring-boot:run --projects book-service
  ```

- Open another terminal and call application endpoints
  ```
  curl -i http://localhost:9080/api/books
  
  curl -i -X POST http://localhost:9080/api/books -H "Content-Type: application/json" \
    -d '{"isbn": "123", "title": "Kong & Keycloak"}'
  
  curl -i http://localhost:9080/api/books/123
  
  curl -i -X DELETE http://localhost:9080/api/books/123
  
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
  | Environment Variable | Description                                                       |
  | -------------------- | ----------------------------------------------------------------- |
  | `MONGODB_HOST`       | Specify host of the `Mongo` database to use (default `localhost`) |
  | `MONGODB_PORT`       | Specify port of the `Mongo` database to use (default `27017`)     |

## Test application Docker Image

- In a terminal, create a Docker network
  ```
  docker network create springboot-kong-keycloak-net
  ```

- Run the command below to start `mongodb` Docker container
  ```
  docker run -d --name mongodb -p 27017:27017 --network springboot-kong-keycloak-net mongo:5.0.4
  ```

- Run the following command to start `book-service` Docker container
  ```
  docker run --rm -p 9080:9080 --name book-service -e MONGODB_HOST=mongodb --network springboot-kong-keycloak-net ivanfranchin/book-service:1.0.0
  ```

- Open another terminal and call application endpoints
  ```
  curl -i http://localhost:9080/api/books
  
  curl -i -X POST http://localhost:9080/api/books -H "Content-Type: application/json" \
    -d '{"isbn": "123", "title": "Kong & Keycloak"}'
  
  curl -i http://localhost:9080/api/books/123
  
  curl -i -X DELETE http://localhost:9080/api/books/123
  
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

- Run the command below
  ```
  docker build -t kong:2.6.0-centos-oidc docker/kong
  ```

## Start Environment

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

  This script creates:
  - `company-services` realm;
  - `book-service` client;
  - user with _username_ `ivan.franchin` and _password_ `123`.

- The `book-service` client secret (`BOOK_SERVICE_CLIENT_SECRET`) is shown at the end of the execution. It will be used in the next step

- You can check the configuration in `Keycloak` by accessing http://localhost:8080. The credentials are `admin/admin`.

## Configure Kong

- In a terminal, make sure you are in `springboot-kong-keycloak` root folder

- Create an environment variable that contains the `Client Secret` generated by `Keycloak` to `book-service` at [Configure Keycloak](#configure-keycloak) step
  ```
  BOOK_SERVICE_CLIENT_SECRET=...
  ```

- Run the following script to configure `Kong` for `book-service` application
  ```
  ./init-kong.sh $BOOK_SERVICE_CLIENT_SECRET
  ```
  
  This script creates:
  - service to `book-service`;
  - route to `/actuator` path;
  - route to `/api` path;
  - add `kong-oidc` plugin to route of `/api` path. It will authenticate users against `Keycloak` OpenID Connect Provider;
  - add `serverless function (post-function)` plugin to route of `/api` path. It gets the access token present in the `X-Userinfo` header provided by `kong-oidc` plugin, decoded it, extracts the `username` and `preferred_username`, and enriches the request with these two information before sending to `book-service`.

## Testing

- Try to call the public `GET /actuator/health` endpoint
  ```
  curl -i http://localhost:8000/actuator/health -H 'Host: book-service'
  ```
  It should return
  ```
  HTTP/1.1 200
  {"status":"UP"}
  ```

- Try to call the private `GET /api/books` endpoint without access token
  ```
  curl -i http://localhost:8000/api/books -H 'Host: book-service'
  ```
  It should return
  ```
  HTTP/1.1 401 Unauthorized
  no Authorization header found
  ```

- Get `ivan.franchin` access token
  ```
  ACCESS_TOKEN=$(./get-access-token.sh $BOOK_SERVICE_CLIENT_SECRET) && echo $ACCESS_TOKEN
  ```

- Call again the private `GET /api/books` endpoint using the access token
  ```
  curl -i http://localhost:8000/api/books -H 'Host: book-service' \
    -H "Authorization: Bearer $ACCESS_TOKEN"
  ```
  It should return
  ```
  HTTP/1.1 200
  []
  ```

- You can try other endpoints using access token

  Create book
  ```
  curl -i -X POST http://localhost:8000/api/books -H 'Host: book-service' \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" -d '{"isbn": "123", "title": "Kong & Keycloak"}'
  ```
  
  Get book
  ```
  curl -i http://localhost:8000/api/books/123 -H 'Host: book-service' \
    -H "Authorization: Bearer $ACCESS_TOKEN"
  ```
  
  Delete book 
  ```
  curl -i -X DELETE http://localhost:8000/api/books/123 -H 'Host: book-service' \
    -H "Authorization: Bearer $ACCESS_TOKEN"
  ```

## Useful Links & Commands

- **MongoDB**

  List books
  ```
  docker exec -it mongodb mongo bookdb
  db.books.find()
  ```
  > Type `exit` to get out of MongoDB shell

- **jwt.io**

  With [jwt.io](https://jwt.io) you can inform the JWT token received from `Keycloak` and the online tool decodes the token, showing its header and payload.

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
