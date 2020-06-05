#!/usr/bin/env sh
apk --no-cache add curl
curl --silent --fail http://app:1010 | grep 'PHP 7.3'
