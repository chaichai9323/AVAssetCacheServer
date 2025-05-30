#!/bin/bash

pod cache clean --all

filepath=$(cd "$(dirname "$0")"; pwd)

cd "$filepath"   #解决文件夹存在空格引起的问题

pod repo push retro-labs-specs-ios-swift AVAssetCacheServer.podspec --allow-warnings --skip-import-validation
