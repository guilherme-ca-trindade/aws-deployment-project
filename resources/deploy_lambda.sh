#!/bin/bash

# --- Configuration ---
LAMBDA_NAME="csd215-lambda"
REGION="us-east-1"
ROOT=.
SOURCE_DIR="$ROOT/app"
BUILD_DIR="lambda_package"
ZIP_FILE="lambda_function.zip"

# -e : exit immediately on error
# -u : treat unset variables as an error
# -x : print the commands as they get executed (so they show up in GitHub Actions logs)
set -eux

# Fail early if LAMBDA_NAME is not set properly
if [[ -z "${LAMBDA_NAME// }" || "$LAMBDA_NAME" == \<* ]]; then
    echo "[ERROR] You did not set LAMBDA_NAME in your deployment script."
    exit 1
fi

echo "--- Starting deployment for $LAMBDA_NAME ---"

echo "[1/4] Cleaning up previous builds..."
rm -rf $BUILD_DIR
rm -f $ZIP_FILE
mkdir -p $BUILD_DIR/app

echo "[2/4] Copying application files..."
cp $SOURCE_DIR/lambda_app.py $BUILD_DIR
cp $SOURCE_DIR/__init__.py $SOURCE_DIR/core.py $SOURCE_DIR/data.py $SOURCE_DIR/lambda_app.py $BUILD_DIR/app

echo "[3/4] Packaging the Lambda function..."
cd $BUILD_DIR
zip -r9 ../$ZIP_FILE ./* -x "*.git*" -x "*.DS_Store" > /dev/null
cd ..

echo "[4/4] Deploying to AWS Lambda..."

export AWS_DEFAULT_REGION="$REGION"
aws lambda update-function-code \
  --function-name "$LAMBDA_NAME" \
  --zip-file fileb://"$ZIP_FILE"

echo "--- Deployment completed for $LAMBDA_NAME ---"
