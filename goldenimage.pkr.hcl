//-on-error=abort
// packer build -var 'tag=1.27.0' .
packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.2" # preferably "~> 1.2.0" for latest patch version
      source = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  timestamp = formatdate("YYYYMMDDhhmm", timestamp())
}

source "amazon-ebs" "amazon_linux2023" {
  force_deregister      = true
  force_delete_snapshot = true
  ami_name              = "${var.app}-${var.tag}"
  ami_description       = "Image of ${var.app} version ${var.tag}"
  instance_type         = "t4g.small"
  region                = "${var.region}"
  #ami_regions           = ["us-west-2"]
  #ami_users             = ["123456789012", "987654321098"]  # List of AWS Account IDs granted launch permissions for the created AMI
  encrypt_boot          = false
  profile               = "${var.aws_profile}"
  iam_instance_profile  = "PackerRole"
  ssh_username          = "ec2-user"
  spot_price            = "auto"
  
  metadata_options {
    instance_metadata_tags = "enabled"
    http_endpoint               = "enabled"
    http_put_response_hop_limit = "1"
    http_tokens                 = "required"
  }

  source_ami_filter {
    filters = {
      name                = "al2023-*-kernel-6.1-arm64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  
  run_tags = {
    Name      = "${var.app}-${var.tag}-packer"
    app       = "${var.app}"
    version   = "${var.tag}"
    timestamp = "${local.timestamp}"
    playbook_name = "ansible-${var.app}"
  }

  tags = {
    Name      = "${var.app}-${var.tag}"
    app       = "${var.app}"
    version   = "${var.tag}"
    timestamp = "${local.timestamp}"
  }
}

build {
  name = "packer"
  sources = [
    "source.amazon-ebs.amazon_linux2023"
  ]

  provisioner "shell" {
    scripts = [
      "goldenimage_script.sh"
    ]
    #inline = [
    #  "curl --connect-timeout 2.37 -m 20 -o /tmp/goldenimage_script.sh https://raw.githubusercontent.com/inqwise/ansible-automation-toolkit/default/goldenimage_script_amzn2023.sh && bash /tmp/goldenimage_script.sh --tags installation",
    #]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
    custom_data = {
      app       = "${var.app}"
      version   = "${var.tag}"
      profile   = "${var.aws_profile}"
      region    = "${var.region}"
    }
  }

  post-processor "shell-local" {
    inline = [
        "if [ -f ./goldenimage_postprocess_temp.sh ]; then",
        "    echo 'Executing local script: goldenimage_postprocess_temp.sh';",
        "    bash ./goldenimage_postprocess_temp.sh;",
        "else",
        "    echo 'Local script not found. Executing remote script: https://raw.githubusercontent.com/inqwise/ansible-automation-toolkit/default/goldenimage_postprocess.sh';",
        "    curl -s https://raw.githubusercontent.com/inqwise/ansible-automation-toolkit/default/goldenimage_postprocess.sh | bash;",
        "fi"
    ]
  }
}
