# Stage 1: Build ChapsDotNet
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build-dotnet
WORKDIR /app

# Copy ChapsDotNet and restore
COPY ChapsDotNet/ ./
RUN dotnet restore ChapsDotNET.csproj

# Build
RUN dotnet publish ChapsDotNET.csproj -c Release -o /out

# Stage 2: Build CHAPS 
FROM mcr.microsoft.com/dotnet/framework/sdk:4.8-windowsservercore-ltsc2019 AS build-chaps
WORKDIR /app

# Copy CHAPS and restore
COPY CHAPS/ ./
# Restore NuGet packages
RUN nuget restore CHAPS.sln

# Build the solution
RUN msbuild /p:Configuration=Release

# Stage 3: Combine and Run
FROM mcr.microsoft.com/dotnet/framework/aspnet:4.8-windowsservercore-ltsc2019 AS runtime
WORKDIR /app

# Copy from build-dotnet
COPY --from=build-dotnet /out ./ChapsDotNet

# Copy from build-chaps
COPY --from=build-chaps /app/Chaps/bin/Release ./CHAPS

# Expose ports if needed
EXPOSE 7226
EXPOSE 44300

# Entry point script (you might need a custom one for running both apps)
CMD ["dotnet", "ChapsDotNet/ChapsDotNET.dll"]
