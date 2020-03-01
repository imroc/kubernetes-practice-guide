#! /bin/bash

set -eux 

OUTPUT="public"

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

msg="rebuilding site `date`"
if [ $# -eq 1  ]
    then msg="$1"
fi

# Build the project. 
hugo -d $OUTPUT # if using a theme, replace by `hugo -t <yourtheme>`

# Go To Public folder
cd $OUTPUT

# Add changes to git.
git add .

# Commit changes.

git commit -m "$msg"

# Push source and build repos.
git push origin gh-pages

# Come Back
cd ..

git add .
git commit -m "$msg"
git push origin master

