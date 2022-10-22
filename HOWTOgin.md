# Go Gin Gonic Skeleton Web App

Gin is a lightweight web framework, similar to Sinatra for Ruby, express.js for Javascript, or Flask for Python.

### Create a new project
```
mkdir -p go-skeleton-crosstree/src/static
cd go-skeleton-crosstree/src
```

#### Create main.go file
```
cat > main.go <<CODE
// https://hackernoon.com/hello-world-in-golang-how-to-develop-a-simple-web-app-in-go-2l39316u
// https://github.com/gin-contrib/static#canonical-example
// https://gin-gonic.com/docs/testing/

package main

import (
	"log"

	"github.com/gin-contrib/static"
	"github.com/gin-gonic/gin"
)

func setupRouter() *gin.Engine {
	r := gin.Default()

	r.GET("/hello", func(c *gin.Context) {
		c.String(200, "Hello, World!")
	})

	api := r.Group("/api")

	api.GET("/ping", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "pong",
		})
	})

	r.Use(static.Serve("/", static.LocalFile("./static", false)))

	return r
}

func main() {
	r := setupRouter()
	
	// Listen and Serve on 0.0.0.0:8000
	if err := r.Run(":8000"); err != nil {
		log.Fatal(err)
	}
}
CODE
```

#### Create a test for it in main_test.go
```
cat > main_test.go << TEST 
// https://gin-gonic.com/docs/testing/
// https://github.com/stretchr/testify

package main

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestHelloRoute(t *testing.T) {
	router := setupRouter()
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/hello", nil)
	router.ServeHTTP(w, req)
	assert.Equal(t, 200, w.Code)
	assert.Contains(t, w.Body.String(), "Hello")
}

func TestApiPingRoute(t *testing.T) {
	router := setupRouter()
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/api/ping", nil)
	router.ServeHTTP(w, req)
	assert.Equal(t, 200, w.Code)
	assert.JSONEq(t, w.Body.String(), `{"message":"pong"}`)
}

func TestRootRoute(t *testing.T) {
	router := setupRouter()
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/", nil)
	router.ServeHTTP(w, req)
	assert.Equal(t, 200, w.Code)
	assert.Contains(t, w.Body.String(), "Welcome")
}
TEST
```

### Running it locally
In Go/Golang, you will need to init the Go Module.   To read more about go modules you can [click here](https://encore.dev/guide/go.mod).

```
cd src
go mod init your-github-org/go-skeleton-crosstree
go mod tidy
go build -v ./...
go test -v ./...
go run . &
```

### Testing and cleaning
```
sleep 5
curl -s http://localhost:8000/api/ping | jq
curl -sI http://localhost:8000/
w3m -dump http://localhost:8000/
sleep 5
kill %%
rm ./go-skeleton-crosstree
```

### Dockerize
```
cat > Dockerfile <<EOF

FROM golang:1.19.2-alpine AS builder
RUN mkdir /build
ADD go.mod go.sum main.go /build/
WORKDIR /build
RUN go build

FROM alpine
RUN adduser -S -D -H -h /app nonroot
USER nonroot
COPY --from=builder /build/go-skeleton-crosstree /app/
COPY static/ /app/static/
WORKDIR /app
EXPOSE 8000:8000
CMD ["./go-skeleton-crosstree"]

EOF

docker build -t go-skeleton-crosstree .
docker run --rm -p 8000:8000 --name skeleton go-skeleton-crosstree &
sleep 5
curl -s http://localhost:8000/api/ping | jq
curl -sI http://localhost:8000/
w3m -dump http://localhost:8000/
sleep 5
docker kill skeleton
```

### Start committing 
```
git init
git add -A
git commit -am "Initial commit"
```


### AWS CLI & GitOps

#### Fargate task definition
```
cat > ops/task-definition.json << EOF 
{
    "containerDefinitions": [
        {
            "name": "go-skeleton-crosstree",
            "image": "*****.dkr.ecr.us-east-1.amazonaws.com/go-skeleton-crosstree:main",
            "cpu": 0,
            "portMappings": [
                {
                    "containerPort": 8000,
                    "hostPort": 8000,
                    "protocol": "tcp"
                }
            ],
            "essential": true,
            "stopTimeout": 30,
            "privileged": false,
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "go-skeleton-crosstree",
                    "awslogs-region": "us-east-1",
                    "awslogs-stream-prefix": "container"
                }
            }
        }
    ],
    "family": "go-skeleton-crosstree",
    "taskRoleArn": "arn:aws:iam::*****:role/go-skeleton-crosstree-task-role",
    "executionRoleArn": "arn:aws:iam::*****:role/go-skeleton-crosstree-task-execution-role",
    "networkMode": "awsvpc",

    "requiresCompatibilities": [
        "FARGATE"
    ],
    "cpu": "256",
    "memory": "512",

    "placementConstraints": []
}
EOF
```

#### GitHub Action IAM policy
```
cat > ops/github-actions-go-skeleton-crosstree-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeImages",
                "ecr:DescribeRepositories",
                "ecr:UploadLayerPart",
                "ecr:ListImages",
                "ecr:InitiateLayerUpload",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetRepositoryPolicy",
                "ecr:PutImage",
                "ecr:GetAuthorizationToken",
                "iam:PassRole",
                "ecs:RegisterTaskDefinition",
                "ecs:DescribeServices",
                "ecs:UpdateService"
            ],
            "Resource": "*"
        }
    ]
}
EOF
```

#### GitHub CI workflow

```
mkdir -p .github/workflows
cat > .github/workflows/ci.yml <<EOF

# https://aws.amazon.com/blogs/opensource/github-actions-aws-fargate/

name: CI to Fargate

on:
  push:
    branches: [ main ]

env:
  AWS_REGION: us-east-1
  AWS_ACCOUNT_ID: *****
  ECS_TASK_DEF: ${{ github.workspace }}/ops/task-definition.json

jobs:
  deploy:
    name: Deploy to Fargate
    runs-on: ubuntu-latest
    # These permissions are needed to interact with GitHub's OIDC Token endpoint.
    permissions:
      id-token: write
      contents: read
    steps:
    - name: Checkout
      uses: actions/checkout@v3

    # https://github.com/aws-actions/configure-aws-credentials
    - name: Configure AWS credentials from Innovation Team Testing account SSO
      uses: aws-actions/configure-aws-credentials@v1
      with:
        role-to-assume: arn:aws:iam::${{ env.AWS_ACCOUNT_ID }}:role/github-actions-${{ github.event.repository.owner.name }}-${{ github.event.repository.name }}
        aws-region: ${{ env.AWS_REGION }}

    # https://github.com/aws-actions/amazon-ecr-login
    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v1

    # https://docs.github.com/en/actions/learn-github-actions/contexts
    - name: Build, tag, and push docker image to Amazon ECR
      run: |
        docker build -t ${{ steps.login-ecr.outputs.registry }}/${{ github.event.repository.name }}:${{ github.sha }} .
        docker push ${{ steps.login-ecr.outputs.registry }}/${{ github.event.repository.name }}:${{ github.sha }} 

    # https://github.com/aws-actions/amazon-ecs-render-task-definition
    - name: Render Amazon ECS task definition
      id: render-web-container
      uses: aws-actions/amazon-ecs-render-task-definition@v1
      with:
        task-definition: ${{ env.ECS_TASK_DEF }}
        container-name: ${{ github.event.repository.name }}
        image: ${{ steps.login-ecr.outputs.registry }}/${{ github.event.repository.name }}:${{ github.sha }} 
        environment-variables: "LOG_LEVEL=info"

    - name: Deploy to Amazon ECS service
      uses: aws-actions/amazon-ecs-deploy-task-definition@v1
      with:
        task-definition: ${{ steps.render-web-container.outputs.task-definition }}
        service: ${{ github.event.repository.name }}
        cluster: ${{ github.event.repository.name }}-cluster
EOF
```

#### Create GitHub worflow file build-n-test.yml

```
cd ..
mkdir -p .github/workflows/
cat > .github/workflows/build-n-test.yml << EOF
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
jobs:
  build-n-test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Set up Go
      uses: actions/setup-go@v3
      with:
        go-version: 1.19
    - name: Build
      run: cd src && go build -v ./...
    - name: Test
      run: cd src && go test -v ./...
EOF
```
