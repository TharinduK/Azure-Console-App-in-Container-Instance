FROM mcr.microsoft.com/dotnet/runtime:6.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src
COPY ["App/DotNet.Docker~.csproj", "App/"]
RUN dotnet restore "App\DotNet.Docker~.csproj"
COPY . .
WORKDIR "/src/App"
RUN dotnet build "DotNet.Docker~.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "DotNet.Docker~.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "DotNet.Docker~.dll"]
