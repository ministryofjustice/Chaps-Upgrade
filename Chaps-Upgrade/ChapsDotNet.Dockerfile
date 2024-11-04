# Stage 1: Build ChapsDotNet (.NET 8)
FROM mcr.microsoft.com/dotnet/sdk:8.0-windowsservercore-ltsc2019 AS build-dotnet
WORKDIR /src

# Copy and restore ChapsDotNet dependencies
COPY ChapsDotNet/ChapsDotNET/ChapsDotNET.csproj ChapsDotNet/ChapsDotNET/
COPY ChapsDotNet/ChapsDotNET.Data/ChapsDotNET.Data.csproj ChapsDotNet/ChapsDotNET.Data/
COPY ChapsDotNet/ChapsDotNET.Business/ChapsDotNET.Business.csproj ChapsDotNet/ChapsDotNET.Business/

# Copy the rest of the project files
COPY ChapsDotNet/ChapsDotNET/ ./ChapsDotNet/ChapsDotNET/
COPY ChapsDotNet/ChapsDotNET.Data/ ./ChapsDotNet/ChapsDotNET.Data/
COPY ChapsDotNet/ChapsDotNET.Business/ ./ChapsDotNet/ChapsDotNET.Business/

WORKDIR /src/ChapsDotNet/ChapsDotNET

RUN dotnet restore ChapsDotNET.csproj

# Publish
RUN dotnet publish ChapsDotNET.csproj -c Release -o /out

# Stage 2: Create ChapsDotNet runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0-windowsservercore-ltsc2019 AS runtime
WORKDIR /app
COPY --from=build-dotnet /out ./

ENTRYPOINT ["dotnet", "ChapsDotNET.dll"]
