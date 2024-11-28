# Stage 1: Build CHAPS (.NET Framework 4.8)
FROM mcr.microsoft.com/dotnet/framework/sdk:4.8-windowsservercore-ltsc2019 AS build-chaps
WORKDIR /src

# Copy CHAPS solution and restore dependencies
COPY CHAPS/ ./CHAPS
COPY bootstrap.ps1 ./

WORKDIR /src/CHAPS

RUN nuget restore -Verbosity quiet Chaps.sln

WORKDIR /src/CHAPS/Chaps
RUN msbuild ../Chaps.sln -verbosity:detailed /m /p:Configuration=Release /p:PlatformTarget=AnyCPU /p:DeployOnBuild=True /p:WebPublishMethod=FileSystem /p:OutputPath=C:\publish /p:DeleteExistingFiles=True
RUN dir C:\publish

# Stage 3:Create CHAPS runtime container with IIS
FROM mcr.microsoft.com/dotnet/framework/aspnet:4.8-windowsservercore-ltsc2019 AS runtime
#WORKDIR /app
WORKDIR /inetpub/wwwroot

RUN mkdir -p C:\chapslogs

# configure IIS to write a global log file:
RUN powershell -Command \
	Set-WebConfigurationProperty -p 'MACHINE/WEBROOT/APPHOST' -fi 'system.applicationHost/log' -n 'centralLogFileMode' -v 'CentralW3C'; \
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/log/centralW3CLogFile' -name 'enabled' -value True; \
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/log/centralW3CLogFile' -name 'truncateSize' -value 4294967295; \
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/log/centralW3CLogFile' -name 'directory' -value 'c:\inetpub\logs\logfiles'

COPY --from=build-chaps /publish/ .

#Use bootstrap to enable logging
WORKDIR /
COPY bootstrap.ps1 ./
ENTRYPOINT ["powershell.exe", "C:\\bootstrap.ps1"]
