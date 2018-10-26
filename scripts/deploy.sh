#!/usr/bin/env bash

# Constraints
SCRIPT_DIR=$( cd $(dirname $0) && pwd -P )
SCRIPT_NAME=$(basename S0)
ROOT_DIR=$( cd $SCRIPT_DIR && cd .. && pwd -P)
APP_NAME="todos"

echo $SCRIPT_DIR
echo $ROOT_DIR

# Constraints
REGION="us-east-1"
S3_BUCKET_NAME="showcase-template-store"
STACK_NAME="${APP_NAME}-Resources"
TEMPLATE_URL="https://s3.amazonaws.com/$S3_BUCKET_NAME/pl-node-on-lambda/CloudFormation/environment-repository.yml"

# Functions
function uploadCFnTemplates() {
  echo "  Syncing files to the S3 bucket from $ROOT_DIR"
  aws s3 sync \
    $ROOT_DIR/CloudFormation/ \
    s3://$S3_BUCKET_NAME/pl-node-on-lambda/CloudFormation/ \
    --region $REGION
  if [ $? -ne 0 ]; then
    echo "error"
    exit 1
  fi
}

function setUpCFnTemplates() {
  echo "[ Set Up CloudFormation Templates ]";
  echo "  Checking the S3 Bucket State ..."
  RESULT=$(aws s3api head-bucket --bucket $S3_BUCKET_NAME)
  if [ $? -eq 0 ]; then
    echo "  Using the existing S3 bucket($S3_BUCKET_NAME) ."
    echo "  Uploading CFn templates to this store.\n"
    uploadCFnTemplates
  elif [ `echo $RESULT | grep 404` ]; then
      RESULT=$(aws s3 mb s3://$S3_BUCKET_NAME/ --region $REGION 2>&1)
      echo "  CFn Templates Store successfully created."
      echo "  Uploading CFn templates to this store.\n"
      uploadCFnTemplates
  else
    echo "  The requested S3 bucket name($S3_BUCKET_NAME) is not available."
    echo "  Please check a name and try again!"
    exit 1
  fi
}

function genConfiguration() {
  RESULT=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME")
  echo $RESULT
}

function deploy() {
  echo "[ Deploy Selenium Grid Resources ]";
    PARAMETERS="ParameterKey=CFnTemplateBucketName,ParameterValue=$S3_BUCKET_NAME"
    PARAMETERS="$PARAMETERS ParameterKey=CFnTemplateBucketRegion,ParameterValue=$REGION"
    PARAMETERS="$PARAMETERS ParameterKey=Repository,ParameterValue=todos"
  aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region ${REGION} 1>/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "  create Selenium Grid resources"
    aws cloudformation create-stack \
      --stack-name "$STACK_NAME" \
      --template-url $TEMPLATE_URL  \
      --parameters $PARAMETERS \
      --region ${REGION} \
      --on-failure DELETE \
      --capabilities CAPABILITY_NAMED_IAM
    if [ $? -eq 0 ]; then
      aws cloudformation wait \
        stack-create-complete \
      --region ${REGION} \
        --stack-name "$STACK_NAME"
    fi
  else
    echo "  update Selenium Grid resources"
    aws cloudformation update-stack \
      --stack-name "$STACK_NAME" \
      --template-url $TEMPLATE_URL \
      --parameters $PARAMETERS \
      --region ${REGION} \
      --capabilities CAPABILITY_NAMED_IAM
    if [ $? -eq 0 ]; then
      aws cloudformation wait \
        stack-update-complete \
      --region ${REGION} \
        --stack-name "$STACK_NAME"
    fi
  fi
}

function deployPipeline() {
  echo "[ Deploy Selenium Grid Resources ]";
    PARAMETERS="ParameterKey=CFnTemplateBucketName,ParameterValue=$S3_BUCKET_NAME"
    PARAMETERS="$PARAMETERS ParameterKey=CFnTemplateBucketRegion,ParameterValue=$REGION"
    PARAMETERS="$PARAMETERS ParameterKey=SourceCodeRepositoryName,ParameterValue=todos"
    STACK_NAME="${APP_NAME}-Pipeline-Resources"
    TEMPLATE_URL="https://s3.amazonaws.com/$S3_BUCKET_NAME/pl-node-on-lambda/CloudFormation/environment-pipeline.yml"
  aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region ${REGION} 1>/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "  create Selenium Grid resources"
    aws cloudformation create-stack \
      --stack-name "$STACK_NAME" \
      --template-url $TEMPLATE_URL  \
      --parameters $PARAMETERS \
      --region ${REGION} \
      --on-failure DELETE \
      --capabilities CAPABILITY_NAMED_IAM
    if [ $? -eq 0 ]; then
      aws cloudformation wait \
        stack-create-complete \
      --region ${REGION} \
        --stack-name "$STACK_NAME"
    fi
  else
    echo "  update Selenium Grid resources"
    aws cloudformation update-stack \
      --stack-name "$STACK_NAME" \
      --template-url $TEMPLATE_URL \
      --parameters $PARAMETERS \
      --region ${REGION} \
      --capabilities CAPABILITY_NAMED_IAM
    if [ $? -eq 0 ]; then
      aws cloudformation wait \
        stack-update-complete \
        --region ${REGION} \
        --stack-name "$STACK_NAME"
    fi
  fi
}

# Main
echo "Set Up Selenium Grid ..."
setUpCFnTemplates
deploy
deployPipeline
