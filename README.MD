# Running .net console application on Azure container instance 

## Prerequisites 
* [Docker Desktop](https://www.docker.com/products/docker-desktop/) >> Sign in to docker desktop
* [.NET SDK](https://dotnet.microsoft.com/en-us/download/visual-studio-sdks)
* [VS.Code](https://code.visualstudio.com)
* VS Code extensions 
  * C# v1.25.2
  * Docker v1.23.2
  * vscode-icons v12.0.1
  * YAML v1.10.1

## Decisions
* Using Linux containers insted of Windows 
  * Hosting Azure containers in Linux is less expensive 
  * Allow using system identity to access container image 
## Experiment 

Check docker and dotnet CLI version 
```shell
# Docker Version
docker --version 

#dotnet sdk version
dotnet --version 
```

### Create console app to run in docker 
1. Create .net application using vs code

*Get supported project templates*
```shell
dotnet new 
```
*Create new console project*
```shell
# dotnet new <short name> -n <project name> -o <project folder>
dotnet new console -n helloConsole -o helloCode.console
dotnet new gitignore
```
*Open project in vs code*
```shell
code .
```
2. Update code to crate sample application that takes value from environment variable 
``` cSharp
Console.WriteLine("Start long running app");

var counter = 0;
var maxCount = Environment.GetEnvironmentVariable("max_count");
var max = string.IsNullOrEmpty(maxCount) ?-1: Convert.ToInt32(maxCount);
while (max == -1 || counter < max)
{
    Console.WriteLine($"Counter: {++counter}");
    await Task.Delay(TimeSpan.FromMilliseconds(1_000));
}

Console.WriteLine("End long running app");
```
3. Add debugging files 
   * "Run and Debug" extension >> "create a launch.json file > .NET 5+ and .NET Core"
![Add debugging file](./doc/AddDebug.png)
   * "Run and Debug" extension >> .NET Core Launch 
  
4. Add docker support using docker extension 
   * Ctrl+Shift+P >> Add docker file..
  ![Add docker file](./doc/AddDockerSupport1.png)
   * Select project type ![Add docker file](./doc/AddDockerSupport2ProjectType.png)
   * Select OS ![Add docker file](./doc/AddDockerSupport3OS.png)
   * No docker compose (single service) ![Add docker file](./doc/AddDockerSupport4DockerCompose.png)

   * Docker file is created 
![Add docker file](./doc/AddDockerSupport5DockerFileAdded.png)
Docker file 
```yaml
FROM mcr.microsoft.com/dotnet/runtime:6.0 AS base
WORKDIR /app

# Creates a non-root user with an explicit UID and adds permission to access the /app folder
# For more info, please refer to https://aka.ms/vscode-docker-dotnet-configure-containers
RUN adduser -u 5678 --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src
COPY ["App/DotNet.Docker~.csproj", "App/"]
RUN dotnet restore "App/DotNet.Docker~.csproj"
COPY . .
WORKDIR "/src/App"
RUN dotnet build "DotNet.Docker~.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "DotNet.Docker~.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "DotNet.Docker~.dll"]
```
5. Debug project in docker 
* "Run and Debug" extension >> "Docker .NET Core Launch
![Add docker file](./doc/LaunchProjectInDocker.png)


### Build and load image to registory 
1. Build a docker image with docker file in the current directory (.)
```shell
# Docker build –t [image name]:[version] -f [docker file location] [path]
image=helloconsole
ver=latest
docker build -t $image:$ver -f ./App/Dockerfile  .
```
2. Setup script variables 
```shell
registry=tkwuscr3 #tkwuscr
image=helloconsole
ver=latest

sub=708854ac-164b-4d34-a0b9-69ff53d7704d
rg=tkcr3-rg #tkcr-rg

```

3. Tag local docker image so it can be pushed to docker registry 
```shell
#docker tag source_image[:tag] target_image[:tag]
docker tag $image:latest $registry.azurecr.io/$image:$ver
```
4. log in to Azure 
```shell
az login
```

5. Set context to correct subscription
```shell
az account set -s $sub
az account list -o table
```

6. Get admin password for ACR and log in to container registry 
```shell
un=$(az acr credential show -n $registry -g $rg --query username -o tsv)
pw=$(az acr credential show -n $registry -g $rg --query passwords[0].value -o tsv)
docker login $registry.azurecr.io -u $un -p $pw
```

5. Push image to registry 
```shell
# docker push [docker registry name]/[Image name]:[version]
docker push $registry.azurecr.io/$image:$ver
```

### Create az container instance using logic app image


Create infrastructure resouces
```shell
registry=tkwuscr4 #tkwuscr
image=helloconsole
ver=latest
sub=708854ac-164b-4d34-a0b9-69ff53d7704d
rg=tkcr4-rg #tkcr-rg
l=centralus

az group create -n $rg -l $l

az deployment group create -n InitialSetup -g $rg \
--mode Incremental \
--template-file template.bicep \
--parameters parameters.json 
```

# Docker CLI commands

* [docker ps <first characters of container name>](https://docs.docker.com/engine/reference/commandline/ps/) >> list containers 
* [docker status <first characters of container name>](https://docs.docker.com/engine/reference/commandline/stats/) > Display a live stream of container(s) resource usage statistics
* [docker inspect <first characters of container name>](https://docs.docker.com/engine/reference/commandline/inspect/) > Return low-level information on Docker objects

# Refernece 
  * [Containerize a .NET app](https://learn.microsoft.com/en-us/dotnet/core/docker/build-container?tabs=windows)
  * [Docker CLI commands](https://docs.docker.com/engine/reference/commandline) 
  * [Azure container instance - logic app integration](https://github.com/Azure-Samples/aci-logicapps-integration)
  * [Deploying an image from Azure Container Registry with Azure Logic Apps](https://soltisweb.com/blog/detail/2021-09-01-deployinganimagefromazurecontainerregistrytoazurelogicapps)