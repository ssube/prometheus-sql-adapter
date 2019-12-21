VERSION_STRING="$(cat package.json | grep '"version":' | sed 's/^.*"version": "\(.*\)",$/\1/')"
>&2 echo "Package version: ${VERSION_STRING}"

IFS="." VERSION_PARTS=( ${VERSION_STRING} )
echo "${VERSION_PARTS[@]}"