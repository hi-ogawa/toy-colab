#!/bin/bash

PROJECT_ID='gcp-vm-cli-test-104884'

REGION='asia-northeast1'
ZONE='asia-northeast1-a'

INSTANCE_NAME='toy-colab'

INSTANCE_OPTS=(
  --preemptible
  --zone=$ZONE

  --image-project=ubuntu-os-cloud
  --image-family=ubuntu-1804-lts
  --metadata-from-file='startup-script=startup-script.sh'

  --boot-disk-size=50GB
  --boot-disk-type=pd-standard
  --network-interface=address # will get ephemeral ip address
)
MACHINE_TYPE_OPTS=(
  --custom-vm-type=n1
  --custom-cpu=4
  --custom-memory=8

  # For pytorch compilation
  # --custom-cpu=16
  # --custom-memory=20
)
ACCELERATOR='nvidia-tesla-t4'

case $1 in
  instance)
    shift
    case $1 in
      create)
        gcloud --project=$PROJECT_ID compute instances create $INSTANCE_NAME "${INSTANCE_OPTS[@]}" "${MACHINE_TYPE_OPTS[@]}"
      ;;
      delete)
        echo 'Y' | gcloud --project=$PROJECT_ID compute instances delete --zone=$ZONE $INSTANCE_NAME
      ;;
      set-machine-type)
        gcloud --project=$PROJECT_ID compute instances set-machine-type $INSTANCE_NAME --zone=$ZONE  "${MACHINE_TYPE_OPTS[@]}"
      ;;
      gpu)
        shift
        case $1 in
          get)
            bash gcp.sh instance -- describe --format='yaml(guestAccelerators)'
          ;;
          # Directly call REST API to change GPU count since gcloud support is not ready yet
          set)
            STATUS=$(bash gcp.sh instance -- describe --format='value(status)')
            test "${STATUS}" != "TERMINATED" && echo ':: It cannot change GPU when VM is not TERMINTATED.' && exit 1
            COUNT=$2
            AUTH=$(gcloud auth print-access-token)
            URL="https://www.googleapis.com/compute/v1/projects/${PROJECT_ID}/zones/${ZONE}/instances/${INSTANCE_NAME}/setMachineResources"
            if test "${COUNT}" = "0"; then
              DATA='{ "guestAccelerators": [] }'
            else
              read -r -d '' DATA <<XXX
                {
                  "guestAccelerators": [
                    {
                      "acceleratorCount": $COUNT,
                      "acceleratorType": "https://www.googleapis.com/compute/v1/projects/${PROJECT_ID}/zones/${ZONE}/acceleratorTypes/${ACCELERATOR}"
                    }
                  ]
                }
XXX
            fi
            curl -X POST "${URL}" -H "Authorization: Bearer ${AUTH}" -H "Content-Type: application/json" -d "${DATA}"
          ;;
        esac
      ;;
      ip)
        gcloud --project=$PROJECT_ID compute instances describe --zone=$ZONE $INSTANCE_NAME \
          --format='value(networkInterfaces[0].accessConfigs[0].natIP)'
      ;;
      # NOTE: It takes some time until "sshd" in VM will oe ready after VM is created (cf "ssh-check" below)
      ssh)
        # TODO: understand what 'gcloud ssh' does
        gcloud --project=$PROJECT_ID compute ssh --zone=$ZONE $INSTANCE_NAME
      ;;
      ssh-run)
        shift
        gcloud --project=$PROJECT_ID compute ssh --zone=$ZONE $INSTANCE_NAME --command="${1}"
      ;;
      ssh-check)
        IP=$(bash gcp.sh instance ip)
        test -z "$IP" && { echo ':: IP address is not available'; exit 1; }
        echo ':: Wait for tcp port 22 to open'
        while true; do
          if nc --wait=1 -z $IP 22; then
            printf '\n:: Port is ready.\n'
            break
          fi
          printf '.'
          sleep 1
        done
      ;;
      startup-log)
        bash gcp.sh instance ssh-run 'journalctl -u google-startup-scripts -f --no-tail'
      ;;
      jupyter)
        shift
        case $1 in
          build)
            gcloud --project=$PROJECT_ID compute scp --zone=$ZONE Dockerfile docker-compose.yml "${INSTANCE_NAME}:~" && \
            bash gcp.sh instance ssh-run 'sudo docker-compose build cuda_jupyter'
          ;;
          up)
            bash gcp.sh instance ssh-run "sudo RUNTIME=${RUNTIME} docker-compose up -d cuda_jupyter"
          ;;
          stop)
            bash gcp.sh instance ssh-run "sudo docker-compose stop cuda_jupyter"
          ;;
          token)
            bash gcp.sh instance ssh-run 'sudo docker-compose exec -T cuda_jupyter pipenv run jupyter notebook list --jsonlist' \
            | jq -r '.[] | .token'
          ;;
          url)
            IP=$(bash gcp.sh instance ip)
            TOKEN=$(bash gcp.sh instance jupyter token)
            echo "https://${IP}:8888/?token=${TOKEN}"
          ;;
        esac
      ;;
      keep-running)
        while true; do
          STATUS=$(bash gcp.sh instance -- describe --format='value(status)')
          if test "${STATUS}" = "TERMINATED"; then
            printf '@\n'
            bash gcp.sh instance -- start
          else
            printf '.'
          fi
          sleep 1
        done
      ;;
      # Deletate to gcloud (e.g. start, stop, ssh, describe, ...)
      --)
        shift
        gcloud --project=$PROJECT_ID compute instances "${@}" --zone=$ZONE $INSTANCE_NAME
      ;;
    esac
  ;;
esac
