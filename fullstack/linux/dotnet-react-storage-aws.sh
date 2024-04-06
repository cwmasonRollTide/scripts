#!/bin/bash

# Create the project
read -p "Enter the project name: " projectName
read -p "Enter the solution name: " solutionName

mkdir -p "$projectName"
cd "$projectName" || exit

echo "Creating the solution and projects..."
mkdir -p Backend
cd Backend || exit
dotnet new sln -n "$solutionName"

read -p "Choose the frontend type (1 - Vite, 2 - Create React App, 3 - Next.js): " frontendType
read -p "Choose the frontend language (1 - TypeScript, 2 - JavaScript): " frontendLang

# Create the frontend project
if [ "$frontendType" = "1" ]; then
    if [ "$frontendLang" = "1" ]; then
        npm init vite@latest ../Client -- --template react-ts
    else
        npm init vite@latest ../Client -- --template react
    fi
elif [ "$frontendType" = "2" ]; then
    if [ "$frontendLang" = "1" ]; then
        npx create-react-app ../Client --template typescript
    else
        npx create-react-app ../Client
    fi
elif [ "$frontendType" = "3" ]; then
    if [ "$frontendLang" = "1" ]; then
        npx create-next-app@latest ../Client --typescript
    else
        npx create-next-app@latest ../Client
    fi
fi

# Create the backend project
dotnet new webapi -n API
dotnet new classlib -n Application
dotnet new classlib -n Domain
dotnet new classlib -n Persistence

echo "Adding projects to the solution..."
dotnet sln add API/API.csproj
dotnet sln add Application/Application.csproj
dotnet sln add Domain/Domain.csproj
dotnet sln add Persistence/Persistence.csproj

echo "Adding project references..."
cd API || exit
dotnet add reference ../Application/Application.csproj
cd ../Application || exit
dotnet add reference ../Domain/Domain.csproj
dotnet add reference ../Persistence/Persistence.csproj
cd ../Persistence || exit
dotnet add reference ../Domain/Domain.csproj
cd ..

echo "Creating Docker and Docker Compose files..."
cd ..
cat <<EOT > Backend/backend.Dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app
COPY . .
RUN dotnet restore
RUN dotnet publish -c Release -o out
RUN mkdir /app/publish
RUN cp -r /app/out /app/publish
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/out .
COPY --from=build /app/publish /app/publish
ENTRYPOINT ["dotnet", "API.dll"]
EOT

cat <<EOT > Client/frontend.Dockerfile
FROM node:18 AS build
WORKDIR /app
COPY . .
RUN npm install
RUN npm run build
FROM nginx:stable-alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOT

cat <<EOT > docker-compose.yml
version: '3'
services:
  backend:
    build:
      context: ./Backend
      dockerfile: backend.Dockerfile
    ports:
      - "5000:80"
EOT

read -p "Choose the storage type (1 - DynamoDB, 2 - Amazon RDS PostgreSQL): " storageType

if [ "$storageType" = "1" ]; then
    cat <<EOT >> docker-compose.yml
  dynamodb-local:
    image: amazon/dynamodb-local
    ports:
      - "8000:8000"
EOT
elif [ "$storageType" = "2" ]; then
    cat <<EOT >> docker-compose.yml
  db:
    image: postgres:14.1
    environment:
      POSTGRES_USER: myuser
      POSTGRES_PASSWORD: mypassword
    ports:
      - "5432:5432"
EOT
fi

cat <<EOT >> docker-compose.yml
  frontend:
    build:
      context: ./Client
      dockerfile: frontend.Dockerfile
    ports:
      - "3000:80"
    depends_on:
      - backend
EOT

# Create the terraform project
echo "Creating Terraform project..."
mkdir -p infrastructure
cd infrastructure || exit

cat <<EOT > variables.tf
variable "domain_name" {
  type        = string
  description = "The domain name for the website"
}

variable "db_username" {
  type        = string
  description = "The username for the database"
}

variable "db_password" {
  type        = string
  description = "The password for the database"
}

variable "environment" {
  type        = string
  description = "The environment (dev or prod)"
  default     = "dev"
}
EOT

cat <<EOT > main.tf
provider "aws" {
  region = "us-east-2"
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
  count             = 2
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.main.id
}

resource "aws_security_group" "backend" {
  name        = "backend-security-group-\${var.environment}"
  description = "Security group for the backend"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_security_group" "frontend" {
  name        = "frontend-security-group-\${var.environment}"
  description = "Security group for the frontend"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_cluster" "main" {
  name = "my-cluster-\${var.environment}"
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "backend-task-\${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  container_definitions    = jsonencode([
    {
      name      = "backend-container-\${var.environment}"
      image     = "backend-image-\${var.environment}"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "frontend-task-\${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  container_definitions    = jsonencode([
    {
      name      = "frontend-container-\${var.environment}"
      image     = "frontend-image-\${var.environment}"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "backend" {
  name            = "backend-service-\${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    security_groups  = [aws_security_group.backend.id]
    subnets          = aws_subnet.public[*].id
    assign_public_ip = true
  }
}

resource "aws_ecs_service" "frontend" {
  name            = "frontend-service-\${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    security_groups  = [aws_security_group.frontend.id]
    subnets          = aws_subnet.public[*].id
    assign_public_ip = true
  }
}

resource "aws_lb" "frontend" {
  name               = "frontend-lb-\${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.frontend.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "frontend" {
  name        = "frontend-target-group-\${var.environment}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
}

resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_route53_zone" "main" {
  name = var.domain_name
}

resource "aws_route53_record" "frontend" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = aws_lb.frontend.dns_name
    zone_id                = aws_lb.frontend.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "frontend" {
  domain_name       = var.domain_name
  validation_method = "DNS"
}

resource "aws_route53_record" "cert_validation" {
  name    = tolist(aws_acm_certificate.frontend.domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.frontend.domain_validation_options)[0].resource_record_type
  zone_id = aws_route53_zone.main.zone_id
  records = [tolist(aws_acm_certificate.frontend.domain_validation_options)[0].resource_record_value]
  ttl     = 60
}

resource "aws_lb_listener" "frontend_https" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.frontend.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}
EOT

if [ "$storageType" = "1" ]; then
    cat <<EOT >> main.tf
resource "aws_dynamodb_table" "main" {
  name           = "my-table-\${var.environment}"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "id"
  attribute {
    name = "id"
    type = "S"
  }
}
EOT
elif [ "$storageType" = "2" ]; then
    cat <<EOT >> main.tf
resource "aws_db_instance" "main" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "14.1"
  instance_class       = "db.t3.micro"
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.postgres14"
  skip_final_snapshot  = true
}
EOT
fi

cat <<EOT >> main.tf
resource "aws_cloudwatch_log_group" "backend" {
  name = "/ecs/backend-\${var.environment}"
}

resource "aws_cloudwatch_log_group" "frontend" {
  name = "/ecs/frontend-\${var.environment}"
}

resource "aws_cloudwatch_log_stream" "backend" {
  name           = "backend-log-stream-\${var.environment}"
  log_group_name = aws_cloudwatch_log_group.backend.name
}

resource "aws_cloudwatch_log_stream" "frontend" {
  name           = "frontend-log-stream-\${var.environment}"
  log_group_name = aws_cloudwatch_log_group.frontend.name
}
EOT

cd ..

cat <<EOT > .gitignore
node_modules/
bin/
obj/
EOT

# Create the Github Action CI/CD
mkdir -p .github/workflows
cd .github/workflows || exit

cat <<EOT > deploy.yml
name: Deploy to AWS
on:
  push:
    branches:
      - main
      - dev
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: \${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: \${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-2
      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1
      - name: Build, tag, and push backend image to Amazon ECR
        env:
          ECR_REGISTRY: \${{ steps.login-ecr.outputs.registry }}
          ECR_REPOSITORY: backend
          IMAGE_TAG: \${{ github.sha }}
        run: |
          docker build -t \$ECR_REGISTRY/\$ECR_REPOSITORY:\$IMAGE_TAG -f backend.Dockerfile ./Backend
          docker push \$ECR_REGISTRY/\$ECR_REPOSITORY:\$IMAGE_TAG
      - name: Build, tag, and push frontend image to Amazon ECR
        env:
          ECR_REGISTRY: \${{ steps.login-ecr.outputs.registry }}
          ECR_REPOSITORY: frontend
          IMAGE_TAG: \${{ github.sha }}
        run: |
          docker build -t \$ECR_REGISTRY/\$ECR_REPOSITORY:\$IMAGE_TAG -f frontend.Dockerfile .
          docker push \$ECR_REGISTRY/\$ECR_REPOSITORY:\$IMAGE_TAG
      - name: Terraform Init
        run: terraform init ./infrastructure
      - name: Terraform Plan
        run: terraform plan -var "environment=\${{ github.ref == 'refs/heads/main' && 'prod' || 'dev' }}" -var "domain_name=\${{ secrets.TF_VAR_domain_name }}" -var "db_username=\${{ secrets.TF_VAR_db_username }}" -var "db_password=\${{ secrets.TF_VAR_db_password }}" ./infrastructure
      - name: Terraform Apply
        if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/dev'
        run: terraform apply -auto-approve -var "environment=\${{ github.ref == 'refs/heads/main' && 'prod' || 'dev' }}" -var "domain_name=\${{ secrets.TF_VAR_domain_name }}" -var "db_username=\${{ secrets.TF_VAR_db_username }}" -var "db_password=\${{ secrets.TF_VAR_db_password }}" ./infrastructure
EOT

cd ..

echo "Executing dotnet restore..."
cd Backend || exit
dotnet restore

echo "Executing npm install..."
cd ../Client || exit
npm install

echo "Finished!"