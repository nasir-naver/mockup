#!/bin/bash

if [ ! -d ../lendit_upload ]; then
  mkdir -p ../lendit_upload_tmp
  mkdir -p ../lendit_upload

  find . -regex "\(.*__pycache__.*\|*.py[co]\)" -delete
  cp -r * ../lendit_upload_tmp
  cp -r deploy/script/* ../lendit_upload_tmp

  cd ../lendit_upload_tmp
  sed -i "s/environment/$DEPLOYMENT_GROUP/g" -i ./restart.sh
  zip -r ../lendit_upload/lendit-outsidebank-$DEPLOYMENT_GROUP-${TRAVIS_COMMIT:0:7} *
  cd ../mockup
fi
