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

# configure IIS to write a global log file:
RUN Set-WebConfigurationProperty -p 'MACHINE/WEBROOT/APPHOST' -fi 'system.applicationHost/log' -n 'centralLogFileMode' -v 'CentralW3C'; \
    Set-WebConfigurationProperty -p 'MACHINE/WEBROOT/APPHOST' -fi 'system.applicationHost/log/centralW3CLogFile' -n 'truncateSize' -v 4294967295; \
    Set-WebConfigurationProperty -p 'MACHINE/WEBROOT/APPHOST' -fi 'system.applicationHost/log/centralW3CLogFile' -n 'period' -v 'MaxSize'; \
    Set-WebConfigurationProperty -p 'MACHINE/WEBROOT/APPHOST' -fi 'system.applicationHost/log/centralW3CLogFile' -n 'directory' -v 'c:\inetpub\logs\logfiles'

# Copy from build-chaps

WORKDIR /inetpub/wwwroot
COPY --from=build-chaps /app/Chaps/bin/Release ./CHAPS
COPY --from=build-chaps /app/Chaps/Web.Release.config ./CHAPS/Web.config

# Enable logging
WORKDIR /
COPY --from=build ./bootstrap.ps1 ./
ENTRYPOINT ["powershell.exe", "C:\\bootstrap.ps1"]

