# AWS IAM Policy Required for Terraform Deployment

## Issue
The AWS IAM user `durganareshpotta83@gmail.com` in account `975050024946` is missing the required permissions to run the Terraform deployment.

### Error Encountered
```
UnauthorizedOperation: You are not authorized to perform this operation.
User: arn:aws:iam::975050024946:user/durganareshpotta83@gmail.com 
is not authorized to perform: ec2:RunInstances
```

## Solution

An AWS Administrator must attach the following IAM policy to your user or group:

### Minimum Required Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:RunInstances",
        "ec2:TerminateInstances",
        "ec2:DescribeInstances",
        "ec2:DescribeImages",
        "ec2:CreateTags",
        "ec2:DeleteTags",
        "ec2:CreateVolume",
        "ec2:DeleteVolume",
        "ec2:DescribeVolumes",
        "ec2:ModifyVolume",
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:DescribeSecurityGroups",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:AllocateAddress",
        "ec2:ReleaseAddress",
        "ec2:AssociateAddress",
        "ec2:DisassociateAddress",
        "ec2:DescribeAddresses",
        "ec2:DescribeNetworkInterfaces",
        "ec2:ModifyNetworkInterfaceAttribute",
        "ec2:DescribeSubnets",
        "ec2:DescribeRouteTables",
        "ec2:CreateRoute",
        "ec2:DeleteRoute",
        "ec2:DescribeRouteTables",
        "ec2:AssociateRouteTable",
        "ec2:DisassociateRouteTable",
        "ec2:DescribeAclsOperations"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:PassRole",
        "iam:CreateRole",
        "iam:PutRolePolicy",
        "iam:CreateInstanceProfile",
        "iam:AddRoleToInstanceProfile",
        "iam:PassRole",
        "iam:GetRole",
        "iam:GetRolePolicy"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:DescribeLogGroups",
        "logs:DeleteLogGroup",
        "logs:PutRetentionPolicy"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricAlarm",
        "cloudwatch:DeleteAlarms",
        "cloudwatch:DescribeAlarms"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "vpc:DescribeVpcs",
        "vpc:DescribeSubnets",
        "vpc:CreateVpc",
        "vpc:DeleteVpc",
        "vpc:CreateSubnet",
        "vpc:DeleteSubnet",
        "vpc:CreateInternetGateway",
        "vpc:DeleteInternetGateway",
        "vpc:AttachInternetGateway",
        "vpc:DetachInternetGateway",
        "vpc:CreateNetworkAcl",
        "vpc:DeleteNetworkAcl",
        "vpc:ModifyNetworkAclEntry",
        "ec2:DescribeNetworkAcls"
      ],
      "Resource": "*"
    }
  ]
}
```

## How to Apply This Policy

### Option 1: AWS Console (Recommended for quick fix)
1. Go to AWS IAM Console: https://console.aws.amazon.com/iam/
2. Navigate to **Users** → Find `durganareshpotta83@gmail.com`
3. Click **Add permissions** → **Attach policies directly**
4. Click **Create inline policy**
5. Paste the JSON policy above
6. Click **Save policy**

### Option 2: AWS CLI (If you have CLI access)
```bash
aws iam put-user-policy \
  --user-name durganareshpotta83@gmail.com \
  --policy-name DurgaTerraformEc2Deployment \
  --policy-document file://ec2-policy.json
```

### Option 3: AWS Management/Administrator applies it
Share this policy document with your AWS Administrator to apply it to your user account.

## After Policy is Applied

Once the policy is attached, retry the Terraform apply:

```bash
cd terraform
terraform apply -auto-approve
```

## Verification

To verify the permissions are working, run:
```bash
aws ec2 describe-instances --region eu-west-2
```

If this command succeeds, your permissions are properly configured.

---
**Note:** This policy is comprehensive for Terraform EC2 deployments. For tighter security, consider restricting resource ARNs or tags after the initial deployment.
