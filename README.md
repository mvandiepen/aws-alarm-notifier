# Alarm notifier

## Terraform

### Installation

```sh
# Terraform CLI
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
terraform init

# AWS CLI
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
rm AWSCLIV2.pkg
```

### Setup

Add [access key](https://console.aws.amazon.com/iam/home?#/security_credentials) from your [AWS account](https://aws.amazon.com/free/?all-free-tier.sort-by=item.additionalFields.SortRank&all-free-tier.sort-order=asc&awsf.Free%20Tier%20Types=*all&awsf.Free%20Tier%20Categories=*all) to `~/.aws/credentials`:

```
[demo-profile]
aws_access_key_id=...
aws_secret_access_key=...
```

Update `aws_key_pair` resource to contain your public key:

```terraform
resource "aws_key_pair" "demo_key" {
  key_name   = "demokey"
  public_key = "ssh-rsa your-public-key-here example@email.com"
}
```

## Slack

### Setup webhook

- Create a [new app](https://api.slack.com/apps?new_app=1) for your slack workspace
- Turn on the `Incoming Webhooks` feature
- Add new webhook to workspace

Update `aws_lambda_function` with your webhook url and the channel you want to notify:

```terraform
resource "aws_lambda_function" "alarm_notifier_lambda" {
  # ... omitted
  
  environment {
    variables = {
      slack_channel     = "#channel-name"
      slack_webhook_url = "your-webhook-url"
    }
  }
}
```

## Lambda

### Changing the function

You can change the lambda function in the `deployment-package` directory. To upload the new function you can run `yarn zip` within the `deployment-package` directory and run `terraform apply` afterwards.

# Ready to run

Just run `terraform plan` to see what will get setup/changed and `terraform apply` to actually apply it.