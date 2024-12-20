provider "aws" {
    region = "ap-south-1"
    access_key = " "
    secret_key = " "
    
  
}

variable "cidr-block" {
    default = "192.0.0.0/16"
}

variable "instance-type" {
    description = "instancr-type"
    default = "t2.medium"
    type = string
  
}

variable "instance_count" {
    description = "instance count"
    type = number
    default = 1
  
}

resource "aws_key_pair" "jenkins-key" {
    key_name = "jenkins-key"
    public_key = file("~/.ssh/id_ed25519.pub")
  
}

resource "aws_vpc" "jenkins-vpc" {
    cidr_block = var.cidr-block
  
}

resource "aws_internet_gateway" "jenkins-gateway" {
    vpc_id = aws_vpc.jenkins-vpc.id 
  
}

resource "aws_subnet" "jenkins-subnet-1" {
    availability_zone = "ap-south-1a"
    cidr_block = "192.0.0.0/24"
    vpc_id = aws_vpc.jenkins-vpc.id
    map_public_ip_on_launch = true
  
}
resource "aws_subnet" "jenkins-subnet-2" {
    availability_zone = "ap-south-1b"
    cidr_block = "192.0.1.0/24"
    vpc_id = aws_vpc.jenkins-vpc.id
    map_public_ip_on_launch = true
  
}

resource "aws_route_table" "jenkins_rt" {
    vpc_id = aws_vpc.jenkins-vpc.id
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.jenkins-gateway.id
    }
  
}

resource "aws_route_table_association" "jenkins_rt_assoc1" {
    subnet_id = aws_subnet.jenkins-subnet-1.id
    route_table_id = aws_route_table.jenkins_rt.id
    
}
resource "aws_route_table_association" "jenkins_rt_assoc2" {
    subnet_id = aws_subnet.jenkins-subnet-2.id
    route_table_id = aws_route_table.jenkins_rt.id
    
}

resource "aws_security_group" "jenkins_sg" {
    vpc_id = aws_vpc.jenkins-vpc.id
    name = "jenkins-sg"

    ingress {
        description = "http connection"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "ssh connection"
        from_port =22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        description = "outgoing connections"
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }


    tags={
        server= "jenkins"
    }
}

resource "aws_instance" "jenkins_server" {
    ami = "ami-053b12d3152c0cc71"
    instance_type = var.instance-type
    count= var.instance_count
    vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
    subnet_id = aws_subnet.jenkins-subnet-1.id
    key_name = aws_key_pair.jenkins-key.key_name

    provisioner "remote-exec" {
        connection {
        type = "ssh"
        user = "ubuntu"
        private_key = file("~/.ssh/id_ed25519")
        host = self.public_ip
    }
        inline = [ 
            
            "sudo apt-get update && sudo apt-get upgrade -y",
        "sudo apt-get install docker.io -y",

        "sudo wget -O /usr/share/keyrings/jenkins-keyring.asc  https://pkg.jenkins.io/debian/jenkins.io-2023.key",

        "echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null",

        "sudo apt-get update",
        "sudo apt-get install fontconfig openjdk-17-jre -y",
        "sudo apt-get install jenkins -y",

        "curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip ",
        "sudo apt install unzip",
        "unzip awscliv2.zip",
        "sudo ./aws/install",
        #aws configure

        "curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl",
        "chmod +x ./kubectl",
        "sudo mv ./kubectl /usr/local/bin",
        "kubectl version --short --client",
        
        "curl --silent --location https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz | tar xz -C /tmp",
        "sudo mv /tmp/eksctl /usr/local/bin",
        "eksctl version",
        

         ]

      
    }


    

    
}
