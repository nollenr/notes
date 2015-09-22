#!/bin/bash
# Deploy from git

echo "************************************************************"
echo "** ${0}                                            **"
echo "************************************************************"
echo "**                                                        **"
echo "** Be sure that ssh-agent is running and that ssh-add     **"
echo "** has been run.                                          **"
echo "**                                                        **"
echo "** As appman                                              **"
echo '** eval `ssh-agent`                                       **'
echo "** ssh-add <it will ask for your password>                **"
echo "**                                                        **"
echo "** two variables will be returned:                        **"
echo "** SSH_AUTH_SOCK                                          **"
echo "** SSH_AGENT_PID                                          **"
echo "**                                                        **"
echo "** Those values need to be updated in the                 **"
echo "** deploy_sub.sh script                                   **"
echo "**                                                        **"
echo "************************************************************"
echo

# variables
  httpdconf="/etc/httpd/conf"
  httpdout="httpd.out.conf"
  httpdalive="httpd.alive.conf"
  maintenancePageDir="/var/www/html"
  maintenancePageFile="maintenance.html"

function maintenance_up {
# check to see if the out and alive confs exist
  currentFunc="maintenance_up"
  if [ ! -d $httpdconf ]; then
    echo "Quitting in function $currentFunc:  The directory \"$httpdconf\" does not exist."
    exit 1
  fi
  if [ ! -f ${httpdconf}/${httpdout} ]; then
    echo "Quitting in function $currentFunc:  The file \"${httpdconf}/${httpdout}\" does not exist."
    exit 1
  fi
  if [ ! -f ${httpdconf}/${httpdalive} ]; then
    echo "Quitting in function $currentFunc:  The file \"${httpdconf}/${httpdalive}\" does not exist."
    exit 1
  fi

# check to see if the maintenance page exists
  if [ ! -d $maintenancePageDir ]; then
    echo "Quitting in function $currentFunc:  The directory \"$maintenancePageDir\" does not exist."
    exit 1
  fi
  if [ ! -f ${maintenancePageDir}/${maintenancePageFile} ]; then
    echo "Quitting in function $currentFunc:  The file \"${maintenancePageDir}/${maintenancePageFile}\" does not exist."
    exit 1
  fi

# copy the outage config file to the standard config and restart the service
  cp ${httpdconf}/${httpdout} ${httpdconf}/httpd.conf
  service httpd restart

}

function site_up {
# copy the alive config file to the standard config and restart the service
  cp ${httpdconf}/${httpdalive} ${httpdconf}/httpd.conf
  service httpd restart

}

# Put the maintenance Up
maintenance_up
param1=${1:-"master"}
echo "  The branch \"${param1}\" will be pulled from git."
su -c "/usr/local/bin/deploy_sub.sh $param1" -s /bin/bash appman
status=$?
if [ $status -ne 0 ]; then
  echo "Deploy unsuccessful.  The site is in maintenance mode."
  exit 1
else
  echo "Deploy successful.  Making the site live."
  site_up
  exit 0
fi

