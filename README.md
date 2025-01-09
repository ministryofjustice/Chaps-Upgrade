# Chaps-Upgrade
Contains submodules for CHAPS and ChapsDotNet repos.   

CHAPS is to be upgraded from a .NET Framework 4.8.1 application to .NET 8.0, using the 'strangler fig' pattern.
The two applications run simultaneously, and users will see the .NET 8.0 application 'ChapsDotNet', which forwards requests to the CHAPS application using YARP reverse proxy. 

Beginning with the /Admin route, ChapsDotNet will return views for any controller routes it can, while the rest are retrieved from the CHAPS application.

# Git management

# Cloning and initialising the repo

Clone the repo: 
git clone --recurse-submodules https://github.com/ministryofjustice/Chaps-Upgrade.git

check submodule status:
git submodule status 
- you should see hashes and paths, which means the submodules are initialised.
  if not, run 
git submodule update --init --recursive
and check the status again. 


# Making changes to one of the projects 

Navigate to the project folder e.g. path/to/Chaps-Upgrade/CHAPS

git add .
git commit -m "changes made to Chaps-Upgrade/CHAPS"
git push origin <branch-name>

Update the submodule reference:
Navigate to the solution root path/to/Chaps-Upgrade

git add CHAPS
git commit -m "update CHAPS submodule to lastes version"
git push origin <branch-name>



