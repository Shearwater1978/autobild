#/bin/bash

# Get all labels from commit messages
labels=$(git rev-list --format=%B --max-count=1 HEAD | grep -vE 'commit' | cut -d ' ' -f 1-)

# Get hash commit to add into label new docker images
fromhash=$(git rev-list --format=%B --max-count=1 HEAD | grep 'commit ' | cut -d ' ' -f 2)

# Convert lables string into array
IFS=', ' read -r -a array <<< "$labels"

for index in "${!array[@]}"
do
    key=$(echo "${array[index]}" | cut -d ":" -f 1)
    value=$(echo "${array[index]}" | cut -d ":" -f 2)
    case $key in
         project)
             DOCKERFILE_LOCATE=$value
             ;;
         image_name)
             DOCKER_IMAGE_NAME=$value
             ;;
         tag)
             DOCKER_IMAGE_TAG=$value
             ;;
    esac
done

# Get number of changed project
project_count=$(git show --pretty="" --name-only $(git rev-parse --short HEAD) > /tmp/git.lst && cat /tmp/git.lst | grep -e '/' | cut -d '/' -f 2 | uniq | wc -l | tr -d '[:space:]')

# Check number of changed project and make decision
case $project_count in
     0)
         echo "Could not detect change in project"
         echo "Script terminating"
         exit 0
         ;;
     1)
         echo "Detect change"
         echo "Proceed work"
         ;;
     *)
         echo "Detect multiply changed project. Not supported"
         echo "Script terminating"
         exit 1
         ;;
esac

# Check that variable DOCKER_IMAGE_TAG set by manually, if not - set automatically
if [ -z $DOCKER_IMAGE_TAG]; then
  echo "DOCKER_IMAGE_TAG not set manually"
  echo "Let set to 'latest'"
  DOCKER_IMAGE_TAG='latest'
fi

# Check that variable DOCKERFILE_LOCATE set by manually, if not - set automatically
if [ -z $DOCKERFILE_LOCATE ]; then
  echo 'DOCKERFILE_LOCATE not set, try to obtain it automatically'
  DOCKERFILE_LOCATE=$(git show --pretty="" --name-only $(git rev-parse --short HEAD) > ./git.lst && cat ./git.lst | grep -e '/' | cut -d '/' -f 2 | uniq)
fi

# Check that variable DOCKER_IMAGE_NAME set by manually, if not - set automatically
if [ -z $DOCKER_IMAGE_NAME]; then
  echo "DOCKER_IMAGE_NAME not set manually"
  echo "Let generate they from DOCKERFILE_LOCATE and prefix 'dvp'"
  DOCKER_IMAGE_NAME='dvp-'$DOCKERFILE_LOCATE
fi

# Check all mandatory vars exists
# Need to validate, because in generic this check shouldn't work
if [ -z $DOCKERFILE_LOCATE ]; then
  echo "Someone variable not exists"
  exit
fi

docker build --no-cache --build-arg http_proxy=$PROXY --build-arg https_proxy=$PROXY . -t $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG -f ./project/$DOCKERFILE_LOCATE/Dockerfile --label "FROM_HASH=$fromhash"
