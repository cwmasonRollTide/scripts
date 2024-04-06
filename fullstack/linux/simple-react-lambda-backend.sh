#!/bin/bash

# Create the project
read -p "Enter the project name: " projectName

mkdir -p "$projectName"
cd "$projectName" || exit

# Create the .github/workflows directory
mkdir -p .github/workflows
touch .github/workflows/deploy.yml

# Create the functions directory
mkdir -p functions/example-function
touch functions/example-function/index.js
touch functions/example-function/package.json

# Create the frontend project
read -p "Choose the frontend type (1 - Vite, 2 - Create React App, 3 - Next.js): " frontendType
read -p "Choose the frontend language (1 - TypeScript, 2 - JavaScript): " frontendLang

if [ "$frontendType" = "1" ]; then
    if [ "$frontendLang" = "1" ]; then
        npm init vite@latest client -- --template react-ts
    else
        npm init vite@latest client -- --template react
    fi
elif [ "$frontendType" = "2" ]; then
    if [ "$frontendLang" = "1" ]; then
        npx create-react-app client --template typescript
    else
        npx create-react-app client
    fi
elif [ "$frontendType" = "3" ]; then
    if [ "$frontendLang" = "1" ]; then
        npx create-next-app@latest client --typescript
    else
        npx create-next-app@latest client
    fi
fi

# Create the infrastructure directory
mkdir -p infrastructure/modules
touch infrastructure/main.tf
touch infrastructure/outputs.tf
touch infrastructure/providers.tf
touch infrastructure/variables.tf

# Create the Terraform configuration files
cat <<EOT > infrastructure/main.tf
# Define your main Terraform configuration here
EOT

cat <<EOT > infrastructure/outputs.tf
# Define your Terraform outputs here
EOT

cat <<EOT > infrastructure/providers.tf
# Define your Terraform providers here
provider "aws" {
  region = var.aws_region
}
EOT

cat <<EOT > infrastructure/variables.tf
# Define your Terraform variables here
variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}
EOT

# Initialize Git repository
git init
cat <<EOT > .gitignore
node_modules/
.terraform/
EOT

echo "Project structure created successfully!"