# Stage 1: Build CHAPS (.NET Framework 4.8)
FROM mcr.microsoft.com/dotnet/framework/sdk:4.8-windowsservercore-ltsc2019 AS build-chaps
WORKDIR /app

# Copy CHAPS solution and restore dependencies
COPY CHAPS/. ./
RUN nuget restore CHAPS.sln

# Build CHAPS
RUN msbuild /p:Configuration=Release /p:PlatformTarget=AnyCPU /p:OutputPath=bin/Release

# Stage 3: Combine & Run
FROM mcr.microsoft.com/dotnet/framework/aspnet:4.8-windowsservercore-ltsc2019 AS runtime
WORKDIR /app

# Copy from build-chaps
COPY --from=build-chaps /app/Chaps/bin/Release ./CHAPS

# Expose both HTTP (80) and HTTPS (443) ports
EXPOSE 80
EXPOSE 443

# HTTPS config in IIS
RUN powershell -NoProfile -Command \
    Import-Module IISAdministration; \
    New-WebBinding -Name "Default Web Site" -Protocol https -Port 443 -IPAddress *; \
    
    New-SelfSignedCertificate -CertStoreLocation cert:\LocalMachine\My -DnsName "localhost"; \
    $thumbprint = (Get-ChildItem -Path cert:\LocalMachine\My | Select-Object -First 1 -ExpandProperty Thumbprint); \
    New-Item -Path IIS:\SslBindings\0.0.0.0!443 -Value $thumbprint

# set rntrypoint to start IIS
ENTRYPOINT ["C:\\ServiceMonitor.exe", "w3svc"]
