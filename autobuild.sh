#/bin/bash

# Get all labels from commit messages
labels=$(git rev-list --format=%B --max-count=1 HEAD | grep -vE 'commit' | cut -d ' ' -f 1-)
fromhash=$(git rev-list --format=%B --max-count=1 HEAD | grep 'commit ' | cut -d ' ' -f 2)

# Convert lables string into array
IFS=', ' read -r -a array <<< "$labels"
#key='^\S+(?=:)'
#value='(?<=:).*$'

for index in "${!array[@]}"
do
    key=$(echo "${array[index]}" | cut -d ":" -f 1)
    value=$(echo "${array[index]}" | cut -d ":" -f 2)
    case $key in
         image_name)
             DOCKER_IMAGE_NAME=$value
             ;;
         tag)
             DOCKER_IMAGE_TAG=$value
             ;;
         id)
             DOCKER_LOCATE=$value
             ;;
    esac
done

# Check all mandatory vars exists
if [ -z $DOCKER_IMAGE_NAME ] || [ -z $DOCKER_IMAGE_TAG ] || [ -z $DOCKER_LOCATE ]; then
  echo -e "Someone variable not exists"
  exit
fi

docker build . -t $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG -f ./$DOCKER_LOCATE/Dockerfile --label "FROM_HASH=$fromhash"
