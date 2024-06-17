#!/usr/bin/env bash
set -euxo pipefail
echo "Start user data"
REGION=$(ec2-metadata --availability-zone | sed -n 's/.*placement: \([a-zA-Z-]*[0-9]\).*/\1/p');
aws s3 cp s3://resource-opinion-stg/get-pip.py - | python3
export VAULT_PASSWORD="{{ vault_password }}"
aws s3 sync s3://bootstrap-opinion-stg/playbooks/ansible-consul /tmp/ansible-consul --region $REGION && cd /tmp/ansible-consul
echo "$VAULT_PASSWORD" > /tmp/ansible-consul/secret
bash main.sh -r $REGION
rm /tmp/ansible-consul/secret
echo "End user data"

# #!/usr/bin/env bash
# set -euxo pipefail
# echo "Start user data"
# curl https://bootstrap.pypa.io/get-pip.py | python3
# aws s3 cp s3://opinion-stg-bootstrap/playbooks/ansible-consul/ /tmp/ansible-consul --recursive && cd /tmp/ansible-consul && bash main.sh
# echo "End user data"