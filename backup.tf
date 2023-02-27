provider "aws" {
  region = "us-east-1"
}

resource "aws_lambda_function" "jenkins_backup_lambda" {
  filename      = "jenkins_backup_lambda.zip"
  function_name = "jenkins-backup-lambda"
  role          = aws_iam_role.jenkins_backup_lambda.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
  timeout       = 30
}

resource "aws_iam_role" "jenkins_backup_lambda" {
  name = "jenkins-backup-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "jenkins_backup_lambda_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = aws_iam_role.jenkins_backup_lambda.name
}

data "aws_ec2_instance" "jenkins_master_instance" {
  filter {
    name   = "tag:Name"
    values = ["jenkins-master"]
  }
}

resource "aws_cloudwatch_event_rule" "jenkins_backup_rule" {
  name        = "jenkins-backup-rule"
  description = "Trigger daily backup of Jenkins master server"

  schedule_expression = "cron(0 6 * * ? *)"
}

resource "aws_cloudwatch_event_target" "jenkins_backup_target" {
  rule      = aws_cloudwatch_event_rule.jenkins_backup_rule.name
  arn       = aws_lambda_function.jenkins_backup_lambda.arn
  target_id = "jenkins-backup-target"
}

resource "null_resource" "jenkins_backup_lambda_zip" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "zip jenkins_backup_lambda.zip lambda_function.py"
  }
}

resource "aws_ssm_parameter" "jenkins_volume_id" {
  name  = "/jenkins/volume_id"
  type  = "String"
  value = data.aws_ec2_instance.jenkins_master_instance.root_block_device[0].volume_id
}

locals {
  snapshot_tags = {
    Name = "Jenkins backup ${timestamp()}"
  }
}

resource "aws_ec2_snapshot" "jenkins_master_snapshot" {
  volume_id = aws_ssm_parameter.jenkins_volume_id.value
  tags = local.snapshot_tags
}






# In this example Terraform code, we create an AWS Lambda function to create a snapshot of the Jenkins master server's EBS volume. We also create a CloudWatch Events rule to trigger the Lambda function daily at a specific time, and an IAM role and policy to grant the Lambda function the necessary permissions. Additionally, we use the AWS SSM Parameter Store to store the Jenkins volume ID and the AWS EC2 Snapshot resource to create a daily snapshot of the volume.

# Note that this is just an example and you may need to modify it to fit your specific requirements. Also, make sure to test your Terraform code thoroughly before deploying it to production.
