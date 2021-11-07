#!/bin/bash

#export NEW_REPO="localcloud-harbor-active-prod.djbx.com"
export NEW_REPO="pubcloud-harbor-prod.djbx.com"
export OLD_REPO="10.7.164.19"
export IMAGES=$(cat ./images.sh | awk '{print $1}')
export IMAGEID=$(cat ./images.sh | awk '{print $2}')

function pull_image()
{
  for i in $IMAGES
  do
    docker pull $i  2&>1  /dev/null
    local imageid=$(docker images $i -q)
    for j in $IMAGEID
    do
       if [ "${imageid}" == "$j" ]; then
          echo " ${i} 镜像id正确"
          break
       fi
    done
  done
}

function push_image()
{
  for i in $IMAGES
  do
    local new_image_name=$(echo ${i/${OLD_REPO}/${NEW_REPO}})
    docker  tag ${i} ${new_image_name}
    docker push ${new_image_name}
  done
}

function main()
{
   pull_image
   push_image
}

main
