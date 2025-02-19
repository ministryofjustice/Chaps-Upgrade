# Stage 1: Build CHAPS (.NET Framework 4.8)
FROM mcr.microsoft.com/dotnet/framework/sdk:4.8-windowsservercore-ltsc2019 AS build-chaps
WORKDIR /src

# Copy CHAPS solution and restore dependencies
COPY CHAPS/ ./CHAPS
COPY bootstrap.ps1 ./
COPY update-config.ps1 /update-config.ps1

WORKDIR /src/CHAPS

RUN nuget locals all -clear
RUN nuget restore Chaps.sln -PackagesDirectory packages C:\src\CHAPS\packages

ENV NUGET_PACKAGES=C:\src\CHAPS\packages

WORKDIR /src/CHAPS/Chaps
RUN msbuild ../Chaps.sln -verbosity:detailed /m /p:Configuration=Release /p:PlatformTarget=AnyCPU /p:DeployOnBuild=True /p:DeployDefaultTarget=WebPublish /p:WebPublishMethod=FileSystem /p:publishUrl=C:\bin /p:DeleteExistingFiles=True /p:RestorePackages=true

RUN dir C:\bin
RUN dir C:\src\CHAPS\packages

# Stage 3:Create CHAPS runtime container with IIS
FROM mcr.microsoft.com/dotnet/framework/aspnet:4.8-windowsservercore-ltsc2019 AS runtime
WORKDIR /inetpub/wwwroot

RUN mkdir -p C:\chapslogs

COPY update-config.ps1 /update-config.ps1
RUN dir /update-config.ps1

#update applicationHost.config
RUN powershell -ExecutionPolicy Bypass -File /update-config.ps1
RUN powershell -Command iisreset

# configure IIS to write a global log file:
RUN powershell -Command \
	Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/log' -name 'centralLogFileMode' -value 'CentralW3C'; \
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/log/centralW3CLogFile' -name 'enabled' -value True; \
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/log/centralW3CLogFile' -name 'truncateSize' -value 4294967295; \
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/log/centralW3CLogFile' -name 'directory' -value 'c:\inetpub\logs\logfiles'

COPY --from=build-chaps /bin /inetpub/wwwroot

#Use bootstrap to enable logging
WORKDIR /
COPY bootstrap.ps1 ./
ENTRYPOINT ["powershell.exe", "C:\\bootstrap.ps1"]
