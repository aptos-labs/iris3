#!/bin/zsh

set -u
set -e
set -x

START=$(date "+%s")

if [[ $# -lt 2 ]]; then
  echo >&2 "Usage: deployment-project project-under-test [execution-id]" \
    "- The project to which Iris is deployed" \
    "- The project where resources will be labeled" \
    "- An optional lower-case alphanumerical string to identify this run," \
    "     used as a prefix on Iris labels and as part of the name of launched resources."
  exit
fi

export RUN_ID
if [[ $# -eq 3 ]]; then
  RUN_ID=$3
else
  # Random value to distinguish this test runs from others
  RUN_ID="iris$(base64 </dev/urandom | tr -d '+/' | head -c 6 | awk '{print tolower($0)}')"
fi

export DEPLOYMENT_PROJECT=$1
export TEST_PROJECT=$2
declare -a projects
projects=("$DEPLOYMENT_PROJECT" "$TEST_PROJECT")
for p in "${projects[@]}"; do
  gcloud projects describe "$p" || {
    echo >&2 "Project $p not found"
    exit 1
  }
done

gcloud config set project "$TEST_PROJECT"

if [ -n "$(echo "$RUN_ID" | grep '[_-]')" ]; then
  echo >&2 "Illegal run id $RUN_ID. No dashes or underlines permitted because " \
    "underlines are illegal in snapshot (and other) names " \
    "and dashes are illegal in BigQuery names."
  exit 1
fi
# Set up the config file for the deployment
mv config.yaml config.yaml.original
function revert_config() {
  echo >&2 "Reverting"
  mv config.yaml.original config.yaml
}

trap "revert_config" INT

envsubst <config.yaml.test.template >config.yaml

./deploy.sh $DEPLOYMENT_PROJECT


function clean_resources() {
  EXIT_CODE=$?
  # The cleanup should not stop on error
  set +e
  # First call the earlier revert
  revert_config

  gcloud compute instances delete "instance${RUN_ID}" -q --project "$TEST_PROJECT"
  gcloud compute snapshots delete "snapshot${RUN_ID}" -q --project "$TEST_PROJECT"
  gcloud compute disks delete "disk${RUN_ID}" -q --project "$TEST_PROJECT"
  gcloud pubsub topics delete "topic${RUN_ID}" -q --project "$TEST_PROJECT"
  gcloud pubsub subscriptions delete "subscription${RUN_ID}" --project "$TEST_PROJECT"
  bq rm -f --table "${TEST_PROJECT}:dataset${RUN_ID}.table${RUN_ID}"
  bq rm -f --dataset "${TEST_PROJECT}:dataset${RUN_ID}"
  gsutil rm -r "gs://bucket${RUN_ID}"
  exit $EXIT_CODE
}

trap "clean_resources" INT

sleep 10 # Need time for traffic to be migrated to the new version

gcloud compute instances create "instance${RUN_ID}" --project "$TEST_PROJECT"
gcloud compute disks create "disk${RUN_ID}" --project "$TEST_PROJECT"
gcloud compute disks snapshot "instance${RUN_ID}" --snapshot-names "snapshot${RUN_ID}" --project $TEST_PROJECT
gcloud pubsub topics create "topic${RUN_ID}" --project "$TEST_PROJECT"
gcloud pubsub subscriptions create "subscription${RUN_ID}" --topic "topic${RUN_ID}" --project "$TEST_PROJECT"
bq mk --dataset "${TEST_PROJECT}:dataset${RUN_ID}"
bq mk --table "${TEST_PROJECT}:dataset${RUN_ID}.table${RUN_ID}"
gsutil mb -p $TEST_PROJECT "gs://bucket${RUN_ID}"

# A test shows that it takes about 3 seconds to  label a new object. However, by creating several types of objects in sequence,
# we allow for more than 3 seconds between creating the object and describing it to check for labels.
false
# jq -e generates exit code 1 on failure. Since we set -e, the script will fail appropriately if the value is not found
gcloud compute instances describe "instance${RUN_ID}" --project "$TEST_PROJECT" --format json --flatten="labels[]" | jq -e ".[0].${RUN_ID}_name"
gcloud compute disks describe "disk${RUN_ID}" --project "$TEST_PROJECT" --format json --flatten="labels[]" | jq -e ".[0].${RUN_ID}_name"
gcloud compute snapshots describe "snapshot${RUN_ID}" --project "$TEST_PROJECT" --format json --flatten="labels[]" | jq -e ".[0].${RUN_ID}_name"
gcloud pubsub topics describe "topic${RUN_ID}" --project "$TEST_PROJECT" --format json --flatten="labels[]" | jq -e ".[0].${RUN_ID}_name"
gcloud pubsub subscriptions describe "subscription${RUN_ID}" --project "$TEST_PROJECT" --format json --flatten="labels[]" | jq -e ".[0].${RUN_ID}_name"
bq show --format=json "${TEST_PROJECT}:dataset${RUN_ID}" | jq -e ".labels.${RUN_ID}_name"
bq show --format=json "${TEST_PROJECT}:dataset${RUN_ID}.table${RUN_ID}" | jq -e ".labels.${RUN_ID}_name"
gsutil label get "gs://bucket${RUN_ID}" | jq -e ".${RUN_ID}_name"

clean_resources

FINISH=$(date "+%s")
ELAPSED_SEC=$((FINISH - START))
echo >&2 "Elapsed time for $(basename "$0") ${ELAPSED_SEC} s"


