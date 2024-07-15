#!/bin/bash

# ENVIRONMENT
# - install jq (for parsing json)
#   Windows:  - download jq https://jqlang.github.io/jq/download/
#             - move jq.exe to a system PATH directory or C:\Program Files\Git\usr\bin if will execute in GitBash
#             - run in GitBash terminal -> ./submit_flink_job.sh
#             - ! jar_name, if use absolute path format "<disk_letter>/<path_to_sh>/jarfile.jar"
#   Ubuntu: sudo apt-get install jq
# HOW TO RUN:
# 1. Start local or remote flink cluster
# 2. Set to PARAMS:
#    - host (if use https host_cert_file, host_cert_type) - jobmanager url
#    - jar_name - path to jar, you want to deploy
#    - job_names_terminate - jobs that will be terminate before run new jobs
# 3. Set path to jar you want to deploy in $jar_name
# 4. Add curls in submit_jobs function
# 5. Run up this sh


# PARAMS
job_names_terminate=(
"job1"
"job2"
)
jar_name="/d/jarfile.jar"
host="localhost:8081"
host_cert_file=""
host_cert_type=""

function submit_jobs() {
    # JOB_ARGS
    kafka_broker="replace_me"
    # job1
    curl -X POST $curl_params -H 'Content-Type: application/json' "$host/jars/$jarid/run" \
    --data-raw '{
          "allowNonRestoredState": true,
          "entryClass": "ru.example.Job1",
          "programArgsList": [
              "--jobName", "Job1",
              "--sourceModule", "Job1",
              "--kafka.group.id", "Job1",
              "--disable-chaining", "false",
              "--inputTopics", "test_topic",
              "--bootstrap.servers",'"\"${kafka_broker}\""'
         ]
    }'
    # job2
    curl -X POST $curl_params -H 'Content-Type: application/json' "$host/jars/$jarid/run" \
    --data-raw '{
          "allowNonRestoredState": true,
          "entryClass": "ru.example.Job2",
          "parallelism": "4",
          "programArgsList": [
              "--jobName", "Job2",
              "--sourceModule", "Job2",
              "--kafka.group.id", "Job2",
              "--disable-chaining", "false",
              "--inputTopics", "test_topic",
              "--bootstrap.servers",'"\"${kafka_broker}\""'
         ]
    }'
}


function parseUploadInput() {
  if [ -z "${userInput}" ]; then
    isUpload=1
  elif [ "y" = "${userInput,,}" ]; then
    isUpload=1
  elif [ "n" = "${userInput,,}" ]; then
    isUpload=0
  else
    echo "Wrong input ${userInput}...exit"
    exit 1
  fi
}
function setCurlParams() {
  if [ -z "$host_cert_file" ]; then
    curl_params=""
  else
    curl_params="-k --cert-type ${host_cert_type} --cert ${host_cert_file}"
  fi
}
function step1() {
    echo ""
    echo "step 1: connection test ${host}"
    response="$(curl -s ${curl_params} ${host}/overview)"
    if [ -z "$response" ]; then
      echo "ERROR: no response from  ${host} response='$response'"
      exit 0
    else
      echo -e "step 1: flink status = \n${response}\n"
    fi

    echo "step 1: terminate jobs"
    jq_query=$(printf ".name==\"%s\" or " "${job_names_terminate[@]}")
    jq_query=${jq_query:0: ${#jq_query} - 4}
    old_job_ids=$(curl -s ${curl_params} ${host}/jobs/overview | jq ".jobs[] | (select(($jq_query) and .state!=\"CANCELED\").jid)" -r)
    if [ -z "$old_job_ids" ]; then
      echo "step 1: no jobs found to terminate"
    else
      echo "step 1:jobs to terminate = $old_job_ids"
      for job_id in $old_job_ids
      do
        echo "step 1: terminating job $job_id"
        curl -X PATCH $curl_params $host/jobs/$job_id
        sleep 1
      done
    fi
}
function step2() {
    echo ""
    echo "step 2: upload or get jar id"
    if [ $isUpload ]; then
      echo "step 2: upload jar"
      status=$(curl -X POST $curl_params -H 'Expect:' -F "jarfile=@$jar_name" $host/jars/upload | jq ".status" -r)
      if [ -z "$status" ] || [ "$status" != "success" ]; then
        echo "ERROR: jar upload failed, status='$status'"
        exit 0
      else
        echo "step 2: jar upload status=${status}"
        jarid=$(curl -s $curl_params $host/jars | jq ".files | max_by(.uploaded) | .id" -r)
      fi
    else
      echo "step 2: last uploaded jar id"
      jarid=$(curl -s $curl_params $host/jars | jq ".files | max_by(.uploaded) | .id" -r)
    fi
    if [ -z "${jarid// }" ]; then
      echo "ERROR: jar_id = null"
      exit 0
    fi
    echo "step 2: jar_id = $jarid"
}


# MAIN
read -p "Upload jar or use last uploaded from cluster?[y/N]: y-default" userInput
parseUploadInput
setCurlParams
echo "host: ${host}"
echo "curl_params: ${curl_params}"
step1
step2
echo ""
echo "step 3: submit job ..."
submit_jobs

