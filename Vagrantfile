# -*- mode: ruby -*-
# vi: set ft=ruby :

# vagrant plugin install vagrant-aws 
# vagrant up --provider=aws
# vagrant destroy -f && vagrant up --provider=aws

AWS_REGION = "il-central-1"
Vagrant.configure("2") do |config|
  config.vm.provision "shell", inline: <<-SHELL
    set -euxo pipefail
    cd /vagrant
    aws s3 cp s3://resource-opinion-stg/get-pip.py - | python3
    echo $PWD
    bash main.sh -r #{AWS_REGION}
  SHELL

  config.vm.provider :aws do |aws, override|
  	override.vm.box = "dummy"
    override.ssh.username = "ec2-user"
    override.ssh.private_key_path = "~/.ssh/id_rsa"
    aws.access_key_id             = `op read "op://Employee/aws inqwise-stg/Security/Access key ID"`.strip!
    aws.secret_access_key         = `op read "op://Employee/aws inqwise-stg/Security/Secret access key"`.strip!
    aws.keypair_name = Etc.getpwuid(Process.uid).name
    override.vm.allowed_synced_folder_types = [:rsync]
    override.vm.synced_folder ".", "/vagrant", type: :rsync, rsync__exclude: ['.git/','ansible-galaxy/'], disabled: false
    override.vm.synced_folder '../ansible-common-collection', '/vagrant/ansible-galaxy', type: :rsync, rsync__exclude: '.git/', disabled: false
    
    aws.region = AWS_REGION
    aws.security_groups = ["sg-0e11a618872a5a387"]
        # public-ssh
    aws.ami = "ami-0bcfb5f8a3f117a50"
    aws.instance_type = "r6g.medium"
    aws.subnet_id = "subnet-0f46c97c53ea11e2e"
    aws.associate_public_ip = true
    aws.iam_instance_profile_name = "bootstrap-role"
    aws.tags = {
      Name: 'consul-test-#{Etc.getpwuid(Process.uid).name}'
    }
  end
end
