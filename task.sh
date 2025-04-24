#!/bin/bash
set -e

echo "Pulling external image: $REPO:$TAG"
docker pull "$REPO:$TAG"

SOURCE_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' "$REPO:$TAG" | cut -d@ -f2)
LOCAL_IMAGE="$ACR_NAME.azurecr.io/$LOCAL_REPO_NAME"

echo "Checking existing digest from ACR (if exists)..."
EXISTING_DIGEST=$(docker manifest inspect "$LOCAL_IMAGE:$TAG" 2>/dev/null | jq -r '.manifests[0].digest')

echo "Source digest: $SOURCE_DIGEST"
echo "ACR digest:    $EXISTING_DIGEST"

if [[ "$SOURCE_DIGEST" == "$EXISTING_DIGEST" ]]; then
  echo "Digest unchanged — no push needed."
  exit 0
fi

DATE_TAG=$(date +%Y%m%d)

echo "Digest changed — tagging and pushing..."
docker tag "$REPO:$TAG" "$LOCAL_IMAGE:$TAG"
docker tag "$REPO:$TAG" "$LOCAL_IMAGE:$DATE_TAG"

docker push "$LOCAL_IMAGE:$TAG"
docker push "$LOCAL_IMAGE:$DATE_TAG"
