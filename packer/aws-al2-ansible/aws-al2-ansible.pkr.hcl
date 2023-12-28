
variables {
  instance_role = "sdh-EC2-access-by-ssm"
}

packer {
  required_plugins {
    amazon = {             # 아마존 리눅스 이미지를 빌드하기 위해 
      version = ">= 0.0.1" # 현재의 버전 
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "amazonlinux2" { # 소스에 사용할 ebs
  ami_name      = "learn-packer-linux-aws"
  instance_type = "t2.micro"       # 이미지를 만들기 위해 인스턴스를 만든다.
  region        = "ap-northeast-2" # 어느 리전에 배포할 것인지 
  source_ami_filter {
    filters = { # filter를 이용해 원하는 이미지를 가져온다.
      name                = "amzn2-ami-kernel-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"] #만약,내가 만은 AMI를 사용을 하려면 내 계정 ID 값을 넣으면 내 AMI 목록에서 가져올 수 있다.
  }
  
  vpc_id = "vpc-0b296f60ef256388b"
  subnet_id = "subnet-0f005cc90389bebf6"
  associate_public_ip_address = false # Public IP 할당 시
  ssh_username         = "ec2-user"

  # SSM 연결 시 
  communicator         = "ssh"
  ssh_interface        = "session_manager"
  iam_instance_profile = var.instance_role

  tags = {
    Name = "learn-packer-linux-aws"
    OS_Version = "amzn2"
    Release = "Latest"
    Base_AMI_ID = "{{ .SourceAMI }}"
    Base_AMI_Name = "{{ .SourceAMIName }}"
    }
}

build {
  name = "learn-packer"
  sources = [
    "source.amazon-ebs.amazonlinux2" # source "amazon-ebs" "amazonlinux2"에서 시작한다.
  ]                            # 이 소스를 가지고 와서 vm을 만들 것이다. 
  # provisioner "shell" {
  #   inline = ["echo Connected via SSM at '${build.User}@${build.Host}:${build.Port}'"]
  # }

  provisioner "ansible" {  # 실제로 vm을 만든 다음 실행할 프로비저너
    playbook_file = "/home/ec2-user/ansible/playbook/main.yml"
    # extra_arguments = [ "-vvvv" ] # debug 용
    use_proxy       = false # ssh 사용 시 기입

    # SSM 이용 시
    ansible_env_vars        =  ["PACKER_BUILD_NAME={{ build_name }}"]
    inventory_file_template =  "{{ .HostAlias }} ansible_host={{ .ID }} ansible_user={{ .User }} ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyCommand=\"sh -c \\\"aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters portNumber=%p\\\"\"'\n"

  }
}