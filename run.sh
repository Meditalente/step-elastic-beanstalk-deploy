#!/bin/bash
set +e

cd "$HOME"
if [ ! -n "$WERCKER_ELASTIC_BEANSTALK_DEPLOY_APP_NAME" ]
then
    fail "Missing or empty option APP_NAME, please check wercker.yml"
fi

if [ ! -n "$WERCKER_ELASTIC_BEANSTALK_DEPLOY_ENV_NAME" ]
then
    fail "Missing or empty option ENV_NAME, please check wercker.yml"
fi

if [ ! -n "$WERCKER_ELASTIC_BEANSTALK_DEPLOY_KEY" ]
then
    fail "Missing or empty option KEY, please check wercker.yml"
fi

if [ ! -n "$WERCKER_ELASTIC_BEANSTALK_DEPLOY_SECRET" ]
then
    fail "Missing or empty option SECRET, please check wercker.yml"
fi

if [ ! -n "$WERCKER_ELASTIC_BEANSTALK_DEPLOY_REGION" ]
then
    warn "Missing or empty option REGION, defaulting to us-west-2"
    WERCKER_ELASTIC_BEANSTALK_DEPLOY_REGION="us-west-2"
fi

if [ -n "$WERCKER_ELASTIC_BEANSTALK_DEPLOY_DEBUG" ]
then
    warn "Debug mode turned on, this can dump potentially dangerous information to log files."
fi

PACKAGES_TO_INSTALL=""

if ! which python
then
  debug "python will be installed"
  PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL python"
fi

if ! which pip
then
  debug "python-pip will be installed"
  PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL python-pip"
fi

if ! which git
then
  debug "git will be installed"
  PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL git"
fi

if [ -n "$PACKAGES_TO_INSTALL" ]
then
  debug "Installing packages: $PACKAGES_TO_INSTALL"
  sudo apt-get install $PACKAGES_TO_INSTALL -y || fail "Failed to install packages $PACKAGES_TO_INSTALL"
fi

if which eb
then
  AWSEB_TOOL=$(which eb)
  info "EB CLI installed at $AWSEB_TOOL"
else
  if which pip
  then
    PIP_TOOL=$(which pip)
    info "pip installed at $PIP_TOOL"
    debug "Installing awsebcli"
    if sudo "$PIP_TOOL" install awsebcli
    then
      info "The awsebcli installed"
      AWSEB_TOOL=$(which eb)
      info "EB CLI installed at $AWSEB_TOOL"
    else
      fail "Unable to install awsebcli"
    fi
  else
    AWSEB_TOOL="$WERCKER_STEP_ROOT/eb-cli/bin/eb"
    info "Using local EB CLI at $AWSEB_TOOL"
  fi
fi

mkdir -p "$HOME/.aws" || fail "Unable to make $HOME/.aws directory"

debug "Change back to the source dir";
cd "$WERCKER_SOURCE_DIR"

AWSEB_CREDENTIAL_FILE="$HOME/.aws/credentials"
AWSEB_CONFIG_FILE="$HOME/.aws/config"
AWSEB_EB_CONFIG_FILE="$WERCKER_SOURCE_DIR/.elasticbeanstalk/config.yml"

debug "Setting up credentials"
cat <<EOT >> $AWSEB_CREDENTIAL_FILE
[default]
aws_access_key_id=$WERCKER_ELASTIC_BEANSTALK_DEPLOY_KEY
aws_secret_access_key=$WERCKER_ELASTIC_BEANSTALK_DEPLOY_SECRET
EOT
if [ $? -ne "0" ]
then
    fail "Unable to set up config file"
fi

debug "Setting up AWS config file"
cat <<EOT >> $AWSEB_CONFIG_FILE
[default]
output = text
region = $WERCKER_ELASTIC_BEANSTALK_DEPLOY_REGION
EOT
if [ $? -ne "0" ]
then
    fail "Unable to set up config file"
fi

debug "Setting up EB config file with eb init"
$AWSEB_TOOL init "$WERCKER_ELASTIC_BEANSTALK_DEPLOY_APP_NAME" || fail "EB is not working or is not set up correctly"

if [ -n "$WERCKER_ELASTIC_BEANSTALK_DEPLOY_DEBUG" ]
then
    debug "Dumping config files."
    echo "=== $AWSEB_CREDENTIAL_FILE ==="
    cat "$AWSEB_CREDENTIAL_FILE"
    echo "=== $AWSEB_CONFIG_FILE ==="
    cat "$AWSEB_CONFIG_FILE"
    echo "=== $AWSEB_EB_CONFIG_FILE ==="
    cat "$AWSEB_EB_CONFIG_FILE"
fi

$AWSEB_TOOL use "$WERCKER_ELASTIC_BEANSTALK_DEPLOY_ENV_NAME" || fail "Unable set EB environment"

debug "Checking if eb exists and can connect"
$AWSEB_TOOL status
if [ $? -ne "0" ]
then
    fail "EB is not working or is not set up correctly"
fi

debug "Pushing to AWS eb servers."
$AWSEB_TOOL deploy && succes'Successfully pushed to Amazon Elastic Beanstalk'
