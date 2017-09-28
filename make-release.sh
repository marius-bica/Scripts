#!/bin/bash

echo 'Switching to master...'
git checkout master

echo 'Delete all local branches just in case...'
git branch | grep -v "master" | xargs git branch -D

echo 'Deleting any existing remote release branches...'
git push origin --delete "release-$1"

echo 'Warming up with a pull...'
git pull

echo 'Pulling branches to be released...'
while read branch; do git checkout $branch; git pull; done < branches

echo 'Creating release branch...'
git checkout -b "release-$1"
echo "Branch release-$1 created"

while read branch; do echo "Merging $branch ..."; git merge $branch; done < branches

echo 'Merge done. Pushing release branch to remote...'
git push --set-upstream origin "release-$1"
echo 'Done'
