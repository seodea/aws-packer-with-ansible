packer {
  required_plugins {
    amazon = {             # 아마존 리눅스 이미지를 빌드하기 위해 
      version = ">= 0.0.1" # 현재의 버전 
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" { # 소스에 사용할 ebs
  ami_name      = "learn-packer-linux-aws"
  instance_type = "t2.micro"       # 이미지를 만들기 위해 인스턴스를 만든다.
  region        = "ap-northeast-2" # 어느 리전에 배포할 것인지 
  source_ami_filter {
    filters = { # filter를 이용해 원하는 이미지를 가져온다.
      name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"] #만약,내가 만은 AMI를 사용을 하려면 내 계정 ID 값을 넣으면 내 AMI 목록에서 가져올 수 있다.
  }
  ssh_username = "ubuntu" # ssh 접속 할 계정 
}

build {
  name = "learn-packer"
  sources = [
    "source.amazon-ebs.ubuntu" # source "amazon-ebs" "ubuntu"에서 시작한다.
  ]                            # 이 소스를 가지고 와서 vm을 만들 것이다. 

  provisioner "shell" {  # 실제로 vm을 만든 다음 실행할 프로비저너
    environment_vars = [ # 가장 기본적인 shell 프로비저너로 
      "FOO=hello world", # 인라인에서 실행한다.
    ]
    inline = [
      "echo Installing Redis",
      "sleep 30",
      "sudo apt-get update",
      "sudo apt-get install -y redis-server",
      "echo \"FOO is $FOO\" > example.txt",
    ]
  }
}