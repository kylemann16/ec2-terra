variable slack_webhook_url  { type = string }

resource aws_sns_topic ec2_ip_update {
    name = "ec2_ip_update"
}

data aws_region current {}
data aws_caller_identity "current" {}

resource aws_sns_topic_policy ec2_ip_update_policy {
    arn = aws_sns_topic.ec2_ip_update.arn
    policy = data.aws_iam_policy_document.sns_access_policy.json
}

data aws_iam_policy_document sns_access_policy {
  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.ec2_ip_update.arn,
    ]

    sid = "__default_statement_ID"

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        data.aws_caller_identity.current.account_id,
      ]
    }
  }

  statement {
    actions = [ "sns:Publish" ]

    effect = "Allow"

    principals {
        type        = "Service"
        identifiers = ["events.amazonaws.com"]
    }

    resources = [
        aws_sns_topic.ec2_ip_update.arn,
    ]

    sid = "__events_access_ID"

  }
}

resource aws_sns_topic_subscription sns_subscription {
    topic_arn = aws_sns_topic.ec2_ip_update.arn
    protocol = "lambda"
    endpoint = aws_lambda_function.notification_lambda.arn
}

################################################################################
###                           CLOUDWATCH EVENT RULE                          ###
################################################################################

resource aws_cloudwatch_event_rule ec2_watcher {
  name        = "watch-ec2-startup-${random_string.run_id.result}"

  event_pattern = jsonencode( {
        "source": ["aws.ec2"],
        "detail-type": ["EC2 Instance State-change Notification"],
        "detail": {
            "instance-id": [ aws_instance.instance.id ]
            "state": ["running"]
        }
    })
}

resource aws_cloudwatch_event_target sns_target {
    rule      = aws_cloudwatch_event_rule.ec2_watcher.name
    target_id = aws_sns_topic.ec2_ip_update.name
    arn       = aws_sns_topic.ec2_ip_update.arn
}

################################################################################
###                             SLACK LAMBDA                                 ###
################################################################################

data archive_file lambda_zip {
    type = "zip"
    source_file = "${path.module}/ec2_info_manip.py"
    output_path = "/tmp/ec2_info_manip.zip"
}

resource aws_lambda_function notification_lambda {
    function_name = "Notification_Lambda_Function_${random_string.run_id.result}"
    filename = data.archive_file.lambda_zip.output_path
    role = aws_iam_role.iam_for_lambda.arn
    runtime = "python3.10"
    handler = "ec2_info_manip.lambda_handler"
    environment {
        variables = {
            SLACK_WEBHOOK_URL = var.slack_webhook_url
            AWS_REGION = data.aws_region.current.name
        }
    }
}

data aws_iam_policy_document assume_role {
    statement {
        effect = "Allow"

        principals {
            type        = "Service"
            identifiers = ["lambda.amazonaws.com"]
        }

        actions = ["sts:AssumeRole"]
    }
}

resource aws_iam_role iam_for_lambda {
    name               = "iam_for_lambda_${random_string.run_id.result}"
    assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data aws_iam_policy_document lambda_allow {
  statement {
        effect = "Allow"

        actions = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
        ]

        resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
        effect = "Allow"
        actions = [
            "ec2:DescribeInstances"
        ]
        resources = ["*"]
  }
}

resource aws_iam_policy lambda_allow {
    name = "slack_lambda_policy_${random_string.run_id.result}"
    policy = data.aws_iam_policy_document.lambda_allow.json
}

resource aws_iam_role_policy_attachment attach_lambda_permissions {
    role       = aws_iam_role.iam_for_lambda.name
    policy_arn = aws_iam_policy.lambda_allow.arn
}


resource "aws_lambda_permission" "with_sns" {
    statement_id  = "AllowExecutionFromSNS"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.notification_lambda.function_name
    principal     = "sns.amazonaws.com"
    source_arn    = aws_sns_topic.ec2_ip_update.arn
}