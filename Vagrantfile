# -*- mode: ruby -*-
# vi: set ft=ruby :

# vagrant plugin install vagrant-aws 
# vagrant up --provider=aws
# vagrant destroy -f && vagrant up --provider=aws

#-r il-central-1 -e "playbook_name=ansible-consul discord_message_owner_name=terra" --topic-name errors --account-id 992382682634

TOPIC_NAME = "errors"
ACCOUNT_ID = "992382682634"
AWS_REGION = "il-central-1"
MAIN_SH_ARGS = <<MARKER
-r #{AWS_REGION} -e "playbook_name=ansible-consul discord_message_owner_name=#{Etc.getpwuid(Process.uid).name}" --topic-name #{TOPIC_NAME} --account-id #{ACCOUNT_ID} --tags configuration
MARKER
NODE_COUNT = 1
CLUSTER_NAME = "#{Etc.getpwuid(Process.uid).name}-test"
Vagrant.configure("2") do |config|
  (1..NODE_COUNT).each do |i|
    config.vm.define "node#{i}" do |subconfig|
      subconfig.vm.provision "shell", inline: <<-SHELL
        set -euxo pipefail
        echo "start vagrant file"
        source /deployment/ansibleenv/bin/activate
        cd /deployment/playbook
        export ANSIBLE_VERBOSITY=0
        export ANSIBLE_DISPLAY_SKIPPED_HOSTS=false
        export VAULT_PASSWORD=#{`op read "op://Security/ansible-vault inqwise-stg/password"`.strip!}
        echo "$VAULT_PASSWORD" > vault_password
        bash main.sh #{MAIN_SH_ARGS}
        rm vault_password
      SHELL
      # subconfig.vm.provision "shell", inline: <<-SHELL
      #   set -euxo pipefail
      #   echo "start vagrant file"
      #   cd /vagrant
      #   python3 -m venv /tmp/ansibleenv
      #   source /tmp/ansibleenv/bin/activate
      #   aws s3 cp s3://resource-opinion-stg/get-pip.py - | python3
      #   echo $PWD
      #   export VAULT_PASSWORD=#{`op read "op://Security/ansible-vault inqwise-stg/password"`.strip!}
      #   echo "$VAULT_PASSWORD" > vault_password
      #   export ANSIBLE_VERBOSITY=0
      #   export ANSIBLE_DISPLAY_SKIPPED_HOSTS=false
      #   if [ -f "main.sh" ]; then
      #     echo "Local main.sh found. Run the local main.sh script..."
      #     bash main.sh #{MAIN_SH_ARGS}
      #   else
      #     echo "Local main.sh not found. running the main.sh script from the URL..."
      #     curl -s https://raw.githubusercontent.com/inqwise/ansible-automation-toolkit/default/main_amzn2023.sh | bash -s -- #{MAIN_SH_ARGS}
      #   fi
      #   rm vault_password
      # SHELL

      subconfig.vm.provider :aws do |aws, override|
        override.vm.box = "dummy"
        override.ssh.username = "ec2-user"
        override.ssh.private_key_path = "~/.ssh/id_rsa"
        aws.access_key_id             = `op read "op://Security/aws inqwise-stg/Security/Access key ID"`.strip!
        aws.secret_access_key         = `op read "op://Security/aws inqwise-stg/Security/Secret access key"`.strip!
        aws.keypair_name = Etc.getpwuid(Process.uid).name
        override.vm.allowed_synced_folder_types = [:rsync]
        override.vm.synced_folder ".", "/vagrant", type: :rsync, rsync__exclude: ['.git/','inqwise/'], disabled: false
        collection_path = ENV['COMMON_COLLECTION_PATH'] || '~/git/ansible-common-collection'
        override.vm.synced_folder collection_path + '/inqwise/common', '/vagrant/inqwise/common', type: :rsync, rsync__exclude: '.git/', disabled: false
        #override.vm.synced_folder '~/git/ansible-stack-trek' + '/inqwise/stacktrek', '/vagrant/inqwise/stacktrek', type: :rsync, rsync__exclude: '.git/', disabled: false
          
        aws.region = AWS_REGION
        aws.security_groups = ["sg-0e11a618872a5a387","sg-00cd6b533fef19ceb"]
        # public-ssh
        #aws.ami = "ami-009b671c6592c55db"
        aws.ami = "ami-0dae830f676c53cee"
        aws.instance_type = "t4g.small"
        aws.subnet_id = "subnet-0f46c97c53ea11e2e"
        aws.associate_public_ip = true
        aws.iam_instance_profile_name = "bootstrap-role"
        aws.tags = {
          Name: "consul-test-#{Etc.getpwuid(Process.uid).name}",
          consul_cluster: "#{CLUSTER_NAME}",
          private_dns: "consul"
        }
      end
    end
  end
end