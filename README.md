# Terraform 入門

# このリポジトリについて

Terraform の勉強用のリポジトリ
Terraform Up&Runningの本のやつです。

## はじめに

Terraform とは infrastructure as code を体現する技術の一つです。
今回はその入門をやっていきます。ちなみにここから下でやることは
Terraform Up & Runningの内容を要約しています。

## 環境構築

1. https://www.terraform.io/downloads.html から自分のOSにあうものをdownloadsしてきます。
2. できたら、一度プロンプト上で **terraform** と叩いて見てください。※1が出ればOK
3. 環境変数の設定をしてください。※2のようにするとbash,zshはできます。
4. シェルを再読み込みしてください。


※1
```
➜  ACL terraform
Usage: terraform [--version] [--help] <command> [args]

The available commands for execution are listed below.
The most common, useful commands are shown first, followed by
less common or more advanced commands. If you're just getting
started with Terraform, stick with the common commands. For the
other commands, please read the help and docs before usage.

Common commands:
apply              Builds or changes infrastructure
console            Interactive console for Terraform interpolations
destroy            Destroy Terraform-managed infrastructure
env                Workspace management
fmt                Rewrites config files to canonical format
get                Download and install modules for the configuration
graph              Create a visual graph of Terraform resources
import             Import existing infrastructure into Terraform
init               Initialize a Terraform working directory
output             Read an output from a state file
plan               Generate and show an execution plan
providers          Prints a tree of the providers used in the configuration
push               Upload this Terraform module to Atlas to run
refresh            Update local state file against real resources
show               Inspect Terraform state or plan
taint              Manually mark a resource for recreation
untaint            Manually unmark a resource as tainted
validate           Validates the Terraform files
version            Prints the Terraform version
workspace          Workspace management

All other commands:
debug              Debug output management (experimental)
force-unlock       Manually unlock the terraform state
state              Advanced state management
```

※2
```
export AWS_ACCESS_KEY_ID=<your key>
export AWS_SECRET_ACCESS_KEY=<your secret key>
```

## simple サーバ構築

早速簡単なインスタンス一つのサーバーを構築するコードを書いていきましょう。
main.tf ファイルを作成してここからは進めていきます。


main.tf
```
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "example" {
  ami           = "ami-40d28157"
  instance_type = "t2.micro"
}
```

とりあえず解説を入れます。

### 解説1

```
provider "aws" {
  region = "us-east-1"
}
```
providerは今回awsを使用するのでawsと指定します。

awsに多様に存在するリージョン(物理サーバの置いてある場所)
を指定します。今回はus-east-1を使用します。
(日本はap-northeast-1です)

```
resource "aws_instance" "example" {
  ami           = "ami-40d28157"
  instance_type = "t2.micro"
}
```
resourceにはどんなリソースを使うのかとこのterraform上でどんな名前を使用するのかを決めます。この場合、aws_instanceというリソースをexampleという名前で使用します。
awsはクラウドサービスなので、サーバの種類が選べます。そのイメージをAmazon Machine Image(AMI)と言います。なので、使いたいイメージのidをamiに指定します。
次に指定しているのがinstance_typeですが、これはawsが規定している、マシンスペックをここで決めます。今回は無料枠が対応している、t2.microというタイプを使用します。

```
$ terraform plan
```
を実行してみてください。

すると「どんなインスタンスがたつか」という情報が見られます。

```
$ terraform apply
```
を次に実行すると、aws上にこのterraformのサーバ情報がデプロイされます。


これでawsコンソールにアクセスするとサーバが立っているはずです。
しかし、インスタンスには適当な名前がついてしまっていると思います。
ここで、名前をつけましょう！！！


main.tf
```
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "example" {
  ami           = "ami-40d28157"
  instance_type = "t2.micro"

  tags {
    Name = "terraform-example"
  }
}
```

こうすることで、このresouceで建てられつインスタンスの名前にタグ付けすることができます。今回はこのインスタンスの名前はterraform-exampleとします。

### web server

では、次はweb serverとして、'Hello World'という文字列を表示しましょう。
以下のようにmain.tfを変更します。


main.tf
```
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "example" {
  ami                    = "ami-40d28157"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF

  tags {
    Name = "terraform-example"
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "public_ip" {
  value = "${aws_instance.example.public_ip}"
}
```

### 解説2

```
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

ここでは、サーバをvpcで枠組みして、一つのサーバにします。そしてそのvpcへのアクセス権限の設定をします。

name：このセキュリティグループの名前をつけます。

ingress：このグループのルールを決めます。

from_port, to_port：8080のポートでやり取りすることを明記しています。

protocol：通信に使用するプロトコルを何にするのかを決めます。今回はtcpを使用するので、tcpにします。

cidr_blocks：どんなip addressを許可するかを決めます。今回はどんなものでも許可したいので、0.0.0.0/0にします。

```
resource "aws_instance" "example" {
  ami                    = "ami-40d28157"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF

  tags {
    Name = "terraform-example"
  }
}
```

次に、ここの解説をしていきまうす。

```
vpc_security_group_ids = ["${aws_security_group.instance.id}"]
```
ここはこのインスタンスがどんなセキュリティグループを使用するかを明記します。
そのidのリストを返すのですが今回は一つだけなので、リストに一つだけ入れます。
terraform では他の手続きを参照して値文字列を代入するとき"${}"を使用します。そして、先ほど設定したセキュリティグループを使用するので、aws_security_group.instance.idとなっています。

```
user_data = <<-EOF
            #!/bin/bash
            echo "Hello, World" > index.html
            nohup busybox httpd -f -p 8080 &
            EOF
```

ここでは実行するシェルスクリプトを含めることができます。
<<-EOFからEOFまでがファイルの内容になります。
今回はHellow Worldをindex.htmlへ書き込み、apacheのweb serverで起動します。

```
output "public_ip" {
  value = "${aws_instance.example.public_ip}"
}
```
これは、デプロイした後プロンプト上にプリントさせる内容を決めています、
instanceの名前を知りたいので、プリントさせます。

## グラフ

```
$ terraform graph
```
このコマンドを実行して吐かれたファイルを、コピーして、http://bit.ly/2mPbxmg にアクセスして、貼り付けると構成図が生成されます。

## 確認
デプロイして確認して見ましょう。そして、生成されたurlにアクセスして、

```
$ curl http://<IP>:8080
Hello, World
```
で確認して見てください

## ファイル分割と変数の使用

```
├── main.tf
├── outputs.tf
└── vars.tf
```

このようなファイル構成にするためにoutputs.tf、vars.tfを作成してください

outputs.tf
```
output "public_ip" {
  value = "${aws_instance.example.public_ip}"
}
```

vars.tf
```
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default     = 8080
}
```
outputs.tf はただ単に、outputsの内容を分割しただけです。
vars.tf はport番号が二つ使っているのと、固定値なので、変数として分離したいです。そのためにはvariableを使用して、変数名を指定します。
descriptionには変数の説明
defaultは最初に決めておく変数の値を入れておきます。


このファイルを分割したことによって以下のようにmain.tfを変更してください。


main.tf
```
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "example" {
  ami                    = "ami-40d28157"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  tags {
    Name = "terraform-example"
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port   = "${var.server_port}"
    to_port     = "${var.server_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```
のように変更してください！
変数参照はvar.<変数名>で扱います

```
from_port   = "${var.server_port}"
```
こんな感じに


## デプロイと確認
同じようにデプロイしてください。
その後以下のコマンドを叩くと
```
$ terraform output public_ip
<ip address>
```

このコマンドはデプロイ後の変数へアクセスしてoutputが見れます。


```
terraform output OUTPUT_NAME
```
