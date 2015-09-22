#!/bin/bash
# Deploy from git

# variables
  datevar=$(date +%Y%m%d%k%M%S)
  appBase="${HOME}/rails"
  appDir="${appBase}/degas"
  gitTempDir=$HOME
  gitTempConfigFile="gitConfig.${datevar}"
  gitConfigDir="${appDir}/.git"
  gitConfigFile="config"
  export SSH_AUTH_SOCK=/tmp/ssh-K15Tr1vqeLyj/agent.29004
  export SSH_AGENT_PID=29005
  branch=${1}


function copy_git_config {
  currentFunc="copy_git_config"
  if [ ! -d $gitTempDir ]; then
    echo "Quitting in function $currentFunc:  The directory \"$gitTempDir\" does not exist."
    exit 1
  fi
  if [ ! -d $gitConfigDir ]; then
    echo "Quitting in function $currentFunc:  The directory \"$gitConfigDir\" does not exist."
    exit 1
  fi
  if [ ! -f ${gitConfigDir}/${gitConfigFile} ]; then
    echo "Quitting in function $currentFunc:  The file \"${gitConfigDir}/${gitConfigFile}\" does not exist."
    exit 1
  fi

  cp ${gitConfigDir}/${gitConfigFile} ${gitTempDir}/${gitTempConfigFile}

  if [ ! -f ${gitTempDir}/${gitTempConfigFile} ]; then
    echo "Quitting in function $currentFunc:  The file \"${gitTempDir}/${gitTempConfigFile}\" does not exist after the copy."
    exit 1
  fi

}

function remove_and_replace_app_dir {
  currentFunc="remove_and_replace_app_dir"
# check if the application directory exists and remove it if it exists
  if [ ! -d $appDir ]; then
    echo "Warning in function $currentFunc:  The directory \"$appDir\" does not exist."
  else
    echo "Removing the app dir ${appDir}".
    rm -rf $appDir
  fi
  if [ -d $appDir ]; then
    echo "Quitting in function $currentFunc:  The directory \"$appDir\" exists after it was deleted."
    exit 1
  fi

# create the application directory
  mkdir -p $appDir
  if [ ! -d $appDir ]; then
    echo "Quitting in function $currentFunc:  The directory \"$appDir\" does not exist after it was recreated."
    exit 1
  fi
}

function git_init_and_config {
  currentFunc="git_init_and_config"
# perform a git init in the app directory
  git init $appDir
  if [ ! -d $gitConfigDir ]; then
    echo "Quitting in function $currentFunc:  The directory \"$gitConfigDir\" does not exist after re-initializing git."
    exit 1
  fi

# copy the config back to the .git dir
  mv ${gitTempDir}/${gitTempConfigFile} ${gitConfigDir}/${gitConfigFile}
  if [ ! -f ${gitConfigDir}/${gitConfigFile} ]; then
    echo "Quitting in function $currentFunc:  The file \"${gitConfigDir}/${gitConfigFile}\" does not exist after reinitializing git and copying the file back."
    exit 1
  fi

}

function git_pull {
  currentFunc="git_pull"
# change to the current app directory
  cd $appDir
  git pull origin $branch
  status=$?
  if [ $status -ne 0 ]; then
    echo "Quitting in function $currentFunc:  The \"git pull\" failed."
    exit 1
  fi
}

function configure_rails {
  currentFunc="configure_rails"
  if [ ! -f ${appDir}/config/database.yml.liszt.aws ]; then
    echo "Quitting in function $currentFunc:  The file \"${appDir}/config/database.yml.liszt.aws\" does not exist."
    exit 1
  fi
  cp ${appDir}/config/database.yml.liszt.aws ${appDir}/config/database.yml

  source "/usr/local/rvm/scripts/rvm"
  status=$?
  if [ $status -ne 0 ]; then
    echo "Quitting in function $currentFunc:  Sourcing \"/usr/local/rvm/scripts/rvm\" failed."
    exit 1
  fi

  rvm gemset use rails3214
  status=$?
  if [ $status -ne 0 ]; then
    echo "Quitting in function $currentFunc:  Using \"gemset\" to set the correct enviornment failed."
    exit 1
  fi

  rm ${appDir}/Gemfile.lock
  cd $appDir
  bundle install --local
  status=$?
  if [ $status -ne 0 ]; then
    echo "Quitting in function $currentFunc:  \"bundle install\" failed."
    exit 1
  fi

  RAILS_ENV=production bundle exec rake assets:precompile
  status=$?
  if [ $status -ne 0 ]; then
    echo "Quitting in function $currentFunc:  \"bundle exec rake assets:precompile\" failed."
    exit 1
  fi

}

copy_git_config
remove_and_replace_app_dir
git_init_and_config
git_pull
configure_rails
exit 0

