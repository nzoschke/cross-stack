require 'aws-sdk'
require 'press'
require 'zip'

extend Press

# Create IAM Role and Policy

iam = Aws::IAM::Client.new
role_arn = nil

pd(event: "iam.create_role") do
  role = iam.create_role(
    role_name: 'lambda_basic_execution',
    assume_role_policy_document: '{
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "",
          "Effect": "Allow",
          "Principal": {
            "Service": "lambda.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }'
  )

  role_arn = role[:role].arn
  pd(event: "iam.create_role", arn: role_arn)
  sleep 5
end

pd(event: "iam.create_role") do
  iam.put_role_policy(
    role_name: "lambda_basic_execution",
    policy_name: "lambda_basic_execution",
    policy_document: '{
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "logs:*"
          ],
          "Resource": "arn:aws:logs:*:*:*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "cloudformation:DescribeStacks"
          ],
          "Resource": "*"
        }
      ]
    }'
  )
end

# Create Lambda Function

lambda = Aws::Lambda::Client.new

pd(event: "lambda.create_function") do
  buffer = Zip::OutputStream.write_buffer do |out|
    out.put_next_entry("index.js")
    out.write File.read("index.js")
  end

  buffer.rewind
  binary_data = buffer.sysread

  func = lambda.create_function(
    function_name: "LookupStackOutputs",
    runtime: "nodejs",
    role: role_arn,
    handler: "index.handler",
    timeout: 10,
    code: {
      zip_file: binary_data
    }
  )
end

# Create Stacks

cf = Aws::CloudFormation::Client.new

pd(event: "cf.create_stack") do
  net_stack = cf.create_stack(
    stack_name:   "SampleNetworkConfiguration",
    template_url: "https://s3.amazonaws.com/cloudformation-examples/lambda/Network.template"
  )

  cf.wait_until(:stack_create_complete, { stack_name: "SampleNetworkConfiguration" })
end

pd(event: "cf.create_stack") do
  app_stack = cf.create_stack(
    stack_name:   "SampleApplication",
    template_url: "https://s3.amazonaws.com/cloudformation-examples/lambda/Application.template",
    parameters: [
      {
        parameter_key: "LambdaFunctionName",
        parameter_value: "LookupStackOutputs",
        use_previous_value: true,
      },
      {
        parameter_key: "NetworkStackName",
        parameter_value: "SampleNetworkConfiguration",
        use_previous_value: true,
      }
    ]
  )

  cf.wait_until(:stack_create_complete, { stack_name: "SampleApplication" })
end