#!/bin/bash
set +e

cd $HOME
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

AWSEB_ROOT="$WERCKER_STEP_ROOT/eb-cli"
AWSEB_TOOL="$AWSEB_ROOT/bin/eb"

#mkdir -p "$HOME/.elasticbeanstalk/"
mkdir -p "$HOME/.aws"
mkdir -p "$WERCKER_SOURCE_DIR/.elasticbeanstalk/"
if [ $? -ne "0" ]
then
    fail "Unable to make directory.";
fi

debug "Change back to the source dir.";
cd $WERCKER_SOURCE_DIR

AWSEB_CREDENTIAL_FILE="$HOME/.aws/aws_credential_file"
AWSEB_CONFIG_FILE="$HOME/.aws/config"
AWSEB_EB_CONFIG_FILE="$WERCKER_SOURCE_DIR/.elasticbeanstalk/config.yml"

debug "Setting up credentials."
cat <<EOT >> $AWSEB_CREDENTIAL_FILE
AWSAccessKeyId=$WERCKER_ELASTIC_BEANSTALK_DEPLOY_KEY
AWSSecretKey=$WERCKER_ELASTIC_BEANSTALK_DEPLOY_SECRET
EOT
if [ $? -ne "0" ]
then
    fail "Unable to set up config file."
fi

debug "Setting up AWS config file."
cat <<EOT >> $AWSEB_CONFIG_FILE
[default]
output = json
region = $WERCKER_ELASTIC_BEANSTALK_DEPLOY_REGION

[profile eb-cli]
aws_access_key_id = $WERCKER_ELASTIC_BEANSTALK_DEPLOY_KEY
aws_secret_access_key = $WERCKER_ELASTIC_BEANSTALK_DEPLOY_SECRET
EOT
if [ $? -ne "0" ]
then
    fail "Unable to set up config file."
fi

debug "Setting up EB config file with eb init."
$AWSEB_TOOL init $WERCKER_ELASTIC_BEANSTALK_DEPLOY_APP_NAME || fail "EB is not working or is not set up correctly."

if [ -n "$WERCKER_ELASTIC_BEANSTALK_DEPLOY_DEBUG" ]
then
    debug "Dumping config files."
    echo "=== $AWSEB_CREDENTIAL_FILE ==="
    cat $AWSEB_CREDENTIAL_FILE
    echo "=== $AWSEB_CONFIG_FILE ==="
    cat $AWSEB_CONFIG_FILE
    echo "=== $AWSEB_EB_CONFIG_FILE ==="
    cat $AWSEB_EB_CONFIG_FILE
fi

$AWSEB_TOOL use $WERCKER_ELASTIC_BEANSTALK_DEPLOY_ENV_NAME || fail "Unable set EB environment."

debug "Checking if eb exists and can connect."
$AWSEB_TOOL status
if [ $? -ne "0" ]
then
    fail "EB is not working or is not set up correctly."
fi

debug "Pushing to AWS eb servers."
$AWSEB_TOOL deploy $WERCKER_ELASTIC_BEANSTALK_DEPLOY_ENV_NAME && success 'Successfully pushed to Amazon Elastic Beanstalk'
