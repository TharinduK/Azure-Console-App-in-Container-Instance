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
  
## Experiment 

1. Check docker and dot net version 
```shell
# Docker Version 
docker --version 
> Docker version 20.10.17, build 100c701

# dotnet sdk version 
dotnet --version 
> 7.0.101
```
### Create console app to run in docker 
2. Create .net application using vs code

```shell
# Get supported project templates 
dotnet new 

# Create new console project 
# dotnet new <short name> -n <project name> -o <project folder>
dotnet new console -n helloConsole -o helloCode.console

# Open project in vs code
code .

```

3. Update code
``` cSharp
// See https://aka.ms/new-console-template for more information
Console.WriteLine("Hello, World!");

var counter = 0;
var max = args.Length != 0 ? Convert.ToInt32(args[0]) : -1;
while (max == -1 || counter < max)
{
    Console.WriteLine($"Counter: {++counter}");
    await Task.Delay(TimeSpan.FromMilliseconds(1_000));
}
```
4. All VS code to add debugging files (popup)
5. Add docker support using docker extension 
   * Ctrl+Shift+P >> Add docker file..
  ![Add docker file](./doc/AddDockerSupport1.png)
   * Select project type ![Add docker file](./doc/AddDockerSupport2ProjectType.png)
  * Select OS ![Add docker file](./doc/AddDockerSupport3OS.png)
  * No docker compose (single service) ![Add docker file](./doc/AddDockerSupport4DockerCompose.png)

Docker file is created 
![Add docker file](./doc/AddDockerSupport5DockerFileAdded.png)
```yaml
FROM mcr.microsoft.com/dotnet/runtime:7.0 AS base
WORKDIR /app

# Creates a non-root user with an explicit UID and adds permission to access the /app folder
# For more info, please refer to https://aka.ms/vscode-docker-dotnet-configure-containers
RUN adduser -u 5678 --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser

FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /src
COPY ["helloCode.console/helloConsole.csproj", "helloCode.console/"]
RUN dotnet restore "helloCode.console/helloConsole.csproj"
COPY . .
WORKDIR "/src/helloCode.console"
RUN dotnet build "helloConsole.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "helloConsole.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "helloConsole.dll"]

```
5. Launch project in docker 
![Add docker file](./doc/LaunchProjectInDocker.png)

### Add connection to SQL server 
1. Add nuget package listed below 
   * Microsoft.Extensions.Configuration
   * Microsoft.Extensions.Configuration.FileExtensions
   * Microsoft.Extensions.Configuration.Json
   * System.Data.SqlClient

2. Add connection string to app settings (appsettings.json)
```json
{
  "ConnectionStrings": {
    "Default": "Server=YOUR_SERVER;Database=mydatabase;User Id=YOUR_USER;Password=YOUR_PASSWORD;MultipleActiveResultSets=true"
  }
}  
```

3. Treate appsettings.json file as content and copy to output directory (file>> properties>> "Copy to output directory: Copy always)

4. Code to query database
   
  ```csharp
using System.Data;
using System.Data.SqlClient;
using Microsoft.Extensions.Configuration;

class Program
{
    public static async Task Main(string[] args)
    {
        var configuration = new ConfigurationBuilder()
            .SetBasePath(Directory.GetCurrentDirectory())
            .AddJsonFile("appsettings.json");
        var config = configuration.Build();

        var connstr = config.GetConnectionString("Default");

        QueryDatabase(connstr);
    }

    private static void QueryDatabase(string? connstr)
    {
        var conn = new SqlConnection();
        conn.ConnectionString = connstr;

        var cmd = conn.CreateCommand();
        cmd.CommandText = @"select top 10 	c.CustomerId AS ID,	c.Company AS CompanyName from Customer c with (nolock)";
        cmd.CommandType = CommandType.Text;
        //cmd.CommandTimeout = _commandTimeout;

        try
        {
            conn.Open();

            var reader = cmd.ExecuteReader();
            while (reader.Read())
            {
                Console.WriteLine($"ID {reader.GetGuid(0).ToString()} Company {reader.GetString(1)}");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error Message: {ex.Message}");
        }
        finally
        {
            conn.Close();
        }
    }
}
```


   
### Add logging

### Configuration 
1. Environment specific variables

2. Secrets (password, API Keys, connection string, license keys, ect.)
3. Runtime knobs (log levels, feature togals)

Layered configuration Order

1. appsettings.json: json-based text file
2. appsettings.<env>.json: based on ASPNETCORE_ENVIRONMENT
3. User secrets: Development-only
4. Environment variables (containers like env var --containers are immutable)
5. Command-line arguments


# Docker CLI commands

* [docker ps <first characters of container name>](https://docs.docker.com/engine/reference/commandline/ps/) >> list containers 
* [docker status <first characters of container name>](https://docs.docker.com/engine/reference/commandline/stats/) > Display a live stream of container(s) resource usage statistics
* [docker inspect <first characters of container name>](https://docs.docker.com/engine/reference/commandline/inspect/) > Return low-level information on Docker objects

# Refernece 
  * [Containerize a .NET app](https://learn.microsoft.com/en-us/dotnet/core/docker/build-container?tabs=windows)
  * [Docker CLI commands](https://docs.docker.com/engine/reference/commandline) 