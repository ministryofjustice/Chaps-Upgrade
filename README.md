# Chaps-Upgrade
Contains submodules for CHAPS and ChapsDotNet repos.   

CHAPS is to be upgraded from a .NET Framework 4.8.1 application to .NET 8.0, using the 'strangler fig' pattern.
The two applications run simultaneously, and users will see the .NET 8.0 application 'ChapsDotNet', which forwards requests to the CHAPS application using YARP reverse proxy. 

ChapsDotNet will return views for any controller routes it can, while the rest are retrieved from the CHAPS application.


# Cloning and initialising the repo

Clone the repo: 
git clone --recurse-submodules https://github.com/ministryofjustice/Chaps-Upgrade.git

check submodule status:
git submodule status 

- you should see hashes and paths, which means the submodules are initialised. If not, run
  
git submodule update --init --recursive

and check the status again. 



# Running locally

The project needs to be run in a Windows environment.

Amend the connection strings:

In ChapsDotNet - this is found in Program.cs under //development config
In Chaps - this is found in the web.Config file. - the Chase database doesn't need a connection string.

Amend the applicationHost.config file.  - found in  .vs/Chaps-Upgrade/config/ in the root directory

CHAPS uses IISExpress, and uses the applicationHost.config file along with the Web.Config file to manage authentication.
Because CHAPS isn't directly exposed to the load balancer, and ChapsDotNet handles all of the auth, we need to disable windows authentication and allow anonymous authentication in Chaps, using the Web.Config file. The applicationHost.config file prevents this change, so we need to change the following lines to "allow":

<sectionGroup name="authentication">
    <section name="anonymousAuthentication" overrideModeDefault="Deny" />
    <section name="windowsAuthentication" overrideModeDefault="Deny" />
</sectionGroup>



# Making changes to ChapsDotNet
In the terminal, navigate to the project folder e.g. path/to/Chaps-Upgrade/ChapsDotNet

git add .
git commit -m "changes made to Chaps-Upgrade/ChapsDotNet"
git push origin <branch-name>

Update the submodule reference:
Navigate to the solution root path/to/Chaps-Upgrade

git add ChapsDotNet
git commit -m "update ChapsDotNet submodule to lastes version"
git push origin <branch-name>
