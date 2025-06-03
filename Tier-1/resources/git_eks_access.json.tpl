{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowSSMParameterRead",
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter"
      ],
      "Resource": "${ssm_parameter_arn}"
    },
    {
      "Sid": "AllowEKSClusterDescribe",
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowEC2AndRDSForTerraform",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeNetworkInterfaces",
        "ec2:DetachNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "rds:DescribeDBInstances",
        "rds:DeleteDBInstance",
        "rds:ModifyDBInstance"
      ],
      "Resource": "*"
    }
  ]
}
