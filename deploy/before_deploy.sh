#!/bin/bash

if [ ! -d ../lendit_upload ]; then
  mkdir -p ../lendit_upload_tmp
  mkdir -p ../lendit_upload

  find . -regex "\(.*__pycache__.*\|*.py[co]\)" -delete
  cp -r * ../lendit_upload_tmp
  cp -r deploy/scripts/* ../lendit_upload_tmp

  cd ../lendit_upload_tmp
  zip -r ../lendit_upload/lendit-outsidebank-$DEPLOYMENT_GROUP-${TRAVIS_COMMIT:0:7} *
  cd ..
  pwd
  ls -al
fi
