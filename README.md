# Chaps-Upgrade
Contains the submodules for CHAPS and ChapsDotNet repos.   

CHAPS is to be upgraded from a .NET Framework 4.8.1 application to .NET 8.0, using the 'strangler fig' pattern.
The two applications run simultaneously, and users will see the .NET 8.0 application 'ChapsDotNet', which forwards requests to the CHAPS application using YARP reverse proxy. 

Beginning with the /Admin route, ChapsDotNet will return views for any controller routes it can, while the rest are retrieved from the CHAPS application.
