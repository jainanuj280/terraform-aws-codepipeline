resource "aws_codedeploy_app" "example" {
  compute_platform = "ECS"
  name             = "example"
}

# data "aws_ecs_cluster" "sample" {
#   cluster_name = "sample"
# }

# data "aws_ecs_service" "service" {
#   service_name = "svc"
#   cluster_arn = data.aws_ecs_cluster.sample.arn
# }

resource "aws_codedeploy_deployment_group" "example" {
  app_name               = aws_codedeploy_app.example.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "example"
  service_role_arn       = aws_iam_role.code-deploy.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.foo.name
    service_name = aws_ecs_service.mongo.name
  }
  
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [data.aws_lb_listener.selected443.arn]
      }

      target_group {
        name = data.aws_lb_target_group.test.name
      }

      target_group {
        name = data.aws_lb_target_group.green.name
      }      

    }
  }   
}

data "aws_lb" "selected" {
  name = "sample"
}

data "aws_lb_listener" "selected443" {
  load_balancer_arn = data.aws_lb.selected.arn
  port              = 80
}

resource "aws_iam_role" "code-deploy" {
  name = "example-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}