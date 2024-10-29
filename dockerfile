# Stage 1: Build ChapsDotNet (.NET 8)
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build-dotnet
WORKDIR /src

# Copy and restore ChapsDotNet dependencies
COPY ChapsDotNet/ChapsDotNET.csproj ChapsDotNet/
RUN dotnet restore ChapsDotNet/ChapsDotNET.csproj

# Build ChapsDotNet
COPY ChapsDotNet/. ./ChapsDotNet/
WORKDIR /src/ChapsDotNet
RUN dotnet publish ChapsDotNET.csproj -c Release -o /out

# Stage 2: Build CHAPS (.NET Framework 4.8)
FROM mcr.microsoft.com/dotnet/framework/sdk:4.8-windowsservercore-ltsc2019 AS build-chaps
WORKDIR /app

# Copy CHAPS solution and restore dependencies
COPY CHAPS/. ./
RUN nuget restore CHAPS.sln

# Build CHAPS
RUN msbuild /p:Configuration=Release /p:PlatformTarget=AnyCPU

# Stage 3: Run
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

# Copy from build-dotnet
COPY --from=build-dotnet /out ./ChapsDotNet

# Copy from build-chaps
COPY --from=build-chaps /app/Chaps/bin/Release ./CHAPS

# Expose the ports required by both applications
EXPOSE 7226
EXPOSE 44300

# Entry point script to run both apps simultaneously (simple example)
CMD ["cmd", "/c", "start dotnet ChapsDotNet/ChapsDotNET.dll && start C:\\CHAPS\\CHAPS.exe"]

