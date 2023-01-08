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
