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

cd ..

cat <<EOT > .gitignore
node_modules/
bin/
obj/
EOT

echo "Executing dotnet restore..."
cd Backend || exit
dotnet restore

echo "Executing npm install..."
cd ../Client || exit
npm install

echo "Finished!"