require 'aws-sdk'

cf = Aws::CloudFormation::Client.new
cf.delete_stack(stack_name: "SampleNetworkConfiguration")
cf.delete_stack(stack_name: "SampleApplication")

lambda = Aws::Lambda::Client.new
lambda.delete_function(function_name: "LookupStackOutputs") rescue nil

iam = Aws::IAM::Client.new
iam.delete_role_policy(policy_name: 'lambda_basic_execution', role_name: 'lambda_basic_execution') rescue nil
iam.delete_role(role_name: 'lambda_basic_execution') rescue nil
