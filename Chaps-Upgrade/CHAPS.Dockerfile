# Stage 1: Build CHAPS (.NET Framework 4.8)
FROM mcr.microsoft.com/dotnet/framework/sdk:4.8-windowsservercore-ltsc2019 AS build-chaps
WORKDIR /app

# Copy CHAPS solution and restore dependencies
COPY CHAPS/. ./
COPY *.sln *.ps1 ./

RUN nuget restore -Verbosity quiet Chaps.sln
RUN msbuild Chaps.sln -verbosity:n /m \
    /p:Configuration=Release \
    /p:DeployOnBuild=True \
    /p:DeployDefaultTarget=WebPublish \
    /p:publishUrl=bin\Release\
    /p:WebPublishMethod=FileSystem \
    /p:DeleteExistingFiles=True \
    /p:DeployOnBuild=True \
    /p:PlatformTarget=AnyCPU

# Stage 3: Combine & Run
FROM mcr.microsoft.com/dotnet/framework/aspnet:4.8-windowsservercore-ltsc2019 AS runtime
WORKDIR /app

# Install IIS
RUN powershell -Command \
    Install-WindowsFeature -Name Web-Server,Web-Http-Logging,Web-Dir-Browsing -IncludeManagementTools 
    
# configure IIS to write a global log file:
RUN Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/log' -name 'centralLogFileMode' -value 'CentralW3C'; \
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/log/centralW3CLogFile' -name 'truncateSize' -value 4294967295; \
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/log/centralW3CLogFile' -name 'period' -value 'MaxSize'; \
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/log/centralW3CLogFile' -name 'directory' -value 'c:\\inetpub\\logs\\logfiles'

# Enable directory browsing
RUN powershell -Command \
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.webServer/directoryBrowse' -name 'enabled' -value 'True'

# Reset IIS
RUN powershell -Command Start-Service W3SVC

# Copy from build-chaps
WORKDIR /inetpub/wwwroot
COPY --from=build-chaps /app/Chaps/bin/Release ./CHAPS
COPY --from=build-chaps /app/Chaps/Web.Release.config ./CHAPS/Web.config

# Enable logging
WORKDIR /
COPY --from=build-chaps /app/bootstrap.ps1 ./
RUN powershell -Command "Set-WebConfigurationProperty -filter 'system.webserver/directoryBrowse' -name enabled -value true"

ENTRYPOINT ["powershell.exe", "C:\\bootstrap.ps1"]
