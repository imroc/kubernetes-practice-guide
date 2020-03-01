#!/bin/bash

function update_zh() {
    cd content
    hugo-algolia -s -i "zh/**" --config ../algolia-zh.yaml --output ../public/algolia.json
    cd ../
}

function update_en() {
    hugo-algolia -s --config algolia-en.yaml -i "content/en/**"
}

function update_all() {
    update_zh
    update_en
}


if [ "$1" == "zh" ]; then
    update_zh
elif [ "$1" == "en" ]; then
    update_en
else
    update_all 
fi