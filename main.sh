#!/bin/bash
while getopts ":e:r:" option
  do
   case "${option}"
   in
    e) EXTRA=${OPTARG};;
    r) REGION=${OPTARG};;
   esac
done
if [ -z "$REGION" ]; 
    then REGION=$(ec2-metadata --availability-zone | sed -n 's/.*placement: \([a-zA-Z-]*[0-9]\).*/\1/p'); 
fi
#REGION=$(ec2-metadata --availability-zone | sed -n 's/.*placement: \([a-zA-Z-]*[0-9]\).*/\1/p')
echo "region:$REGION"

catch_error () {
    INSTANCE_ID=$(ec2-metadata --instance-id | sed -n 's/.*instance-id: \(i-[a-f0-9]\{17\}\).*/\1/p')
    echo "An error occurred: $1"
    aws sns publish --topic-arn "arn:aws:sns:$REGION:992382682634:errors" --message "$1" --subject "$INSTANCE_ID" --region $REGION
}
main () {
    set -euxo pipefail
    pip install -r requirements.txt --user virtualenv --timeout 60
    export PATH=$PATH:~/.local/bin
    export ANSIBLE_ROLES_PATH="$(pwd)/ansible-galaxy/roles"
    ansible-galaxy install -p roles -r requirements.yml
    ansible-playbook main.yml --syntax-check
    ansible-playbook --connection=local --inventory 127.0.0.1, --limit 127.0.0.1 main.yml
}
trap 'catch_error "$ERROR"' ERR
{ ERROR=$(main 2>&1 1>&$out); } {out}>&1