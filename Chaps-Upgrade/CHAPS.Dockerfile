# Stage 1: Build CHAPS (.NET Framework 4.8)
FROM mcr.microsoft.com/dotnet/framework/sdk:4.8-windowsservercore-ltsc2019 AS build-chaps
WORKDIR /app

# Copy CHAPS solution and restore dependencies
COPY CHAPS/ ./CHAPS
COPY *.ps1 ./

WORKDIR /app/CHAPS

RUN nuget restore -Verbosity quiet Chaps.sln

WORKDIR /app/CHAPS/Chaps

RUN msbuild ../Chaps.sln -verbosity:n /m \
    /p:Configuration=Release \
    /p:OutputPath=C:\app\CHAPS\Chaps\bin\Release \
    /p:PlatformTarget=AnyCPU \
    /p:DeployOnBuild=True \
    /p:WebPublishMethod=FileSystem \
    /p:publishUrl=C:\app\CHAPS\Chaps\bin\PublishedOutput\
    /p:DeleteExistingFiles=True

# Stage 3: Combine & Run
FROM mcr.microsoft.com/dotnet/framework/aspnet:4.8-windowsservercore-ltsc2019 AS runtime
WORKDIR /app

RUN mkdir -p C:\inetpub\logs\logfiles\W3SVC1

RUN powershell -Command \
    Install-WindowsFeature Web-AppInit,Web-Asp-Net45

# configure IIS to write a global log file:
RUN powershell -Command \
	Set-WebConfigurationProperty -p 'MACHINE/WEBROOT/APPHOST' -fi 'system.applicationHost/log' -n 'centralLogFileMode' -v 'CentralW3C'; \
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/log/centralW3CLogFile' -name 'enabled' -value True; \
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/log/centralW3CLogFile' -name 'truncateSize' -value 4294967295; \
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter 'system.applicationHost/log/centralW3CLogFile' -name 'directory' -value 'c:\inetpub\logs\logfiles'

RUN powershell -Command \
Install-WindowsFeature Web-AppInit,Web-Asp-Net45

# Copy from build-chaps
WORKDIR /inetpub/wwwroot
COPY --from=build-chaps /app/CHAPS/Chaps/bin/Release ./Release
#COPY --from=build-chaps /app/CHAPS/Chaps/Web.Release.config ./Web.config
COPY --from=build-chaps /app/CHAPS/Chaps/obj/Release/TransformWebConfig/transformed/Web.config ./Web.config

# Enable logging
WORKDIR /
COPY --from=build-chaps /app/bootstrap.ps1 ./
ENTRYPOINT ["powershell.exe", "C:\\bootstrap.ps1"]
