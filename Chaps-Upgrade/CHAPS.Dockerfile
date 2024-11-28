# Stage 1: Build CHAPS (.NET Framework 4.8)
FROM mcr.microsoft.com/dotnet/framework/sdk:4.8-windowsservercore-ltsc2019 AS build-chaps
WORKDIR /src

# Copy CHAPS solution and restore dependencies
COPY CHAPS/ ./CHAPS

WORKDIR /src/CHAPS

RUN nuget restore -Verbosity quiet Chaps.sln

WORKDIR /src/CHAPS/Chaps
RUN msbuild ../Chaps.sln -verbosity:n /m \
    /p:Configuration=Release \
    /p:PlatformTarget=AnyCPU \
    /p:DeployOnBuild=True \
    /p:WebPublishMethod=FileSystem \
    /p:publishUrl=C:\out \
    /p:DeleteExistingFiles=True

# Debug
RUN dir C:\

# Stage 3:Create CHAPS runtime container with IIS
FROM mcr.microsoft.com/dotnet/framework/aspnet:4.8-windowsservercore-ltsc2019 AS runtime
#WORKDIR /app
WORKDIR /inetpub/wwwroot

RUN mkdir -p C:\chapslogs
#RUN mkdir -p C:\inetpub\logs\logfiles\W3SVC1

# configure IIS to write a global log file:
RUN powershell -Command \
	Set-WebConfigurationProperty -p 'MACHINE/WEBROOT/APPHOST' -fi 'system.applicationHost/log' -n 'centralLogFileMode' -v 'CentralW3C'; \
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/log/centralW3CLogFile' -name 'enabled' -value True; \
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/log/centralW3CLogFile' -name 'truncateSize' -value 4294967295; \
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/log/centralW3CLogFile' -name 'directory' -value 'c:\inetpub\logs\logfiles'

# Copy from build-chaps
#WORKDIR /inetpub/wwwroot
#COPY --from=build-chaps /app/CHAPS/Chaps/bin/Release ./bin
#COPY --from=build-chaps /app/CHAPS/Chaps/obj/Release/TransformWebConfig/transformed/Web.config ./Web.config
#COPY --from=build-chaps /app/CHAPS/Chaps/Views ./Views
#COPY --from=build-chaps /app/CHAPS/Chaps/Content ./Content
#COPY --from=build-chaps /app/CHAPS/Chaps/Scripts ./Scripts
COPY --from=build-chaps /out/ .

# Enable logging
WORKDIR /
COPY --from=build-chaps /src/bootstrap.ps1 ./
ENTRYPOINT ["powershell.exe", "C:\\bootstrap.ps1"]
