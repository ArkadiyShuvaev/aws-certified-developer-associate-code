# https://docs.aws.amazon.com/lambda/latest/dg/provisioned-concurrency.html
# https://aws.amazon.com/ru/blogs/compute/scheduling-aws-lambda-provisioned-concurrency-for-recurring-peak-usage/

# Managing provisioned concurrency with Application Auto Scaling
# Application Auto Scaling allows you to manage provisioned concurrency on a schedule or based on utilization.
# Use a target tracking scaling policy if want your function to maintain a specified utilization percentage, 
# and scheduled scaling to increase provisioned concurrency in anticipation of peak traffic.

# Register a function's alias as a scaling target.
aws application-autoscaling register-scalable-target --service-namespace lambda --resource-id function:StockQuoteService:1 --min-capacity 1 --max-capacity 5 --scalable-dimension lambda:function:ProvisionedConcurrency
                        
# Apply a scaling policy to the target.                     

aws application-autoscaling put-scaling-policy --service-namespace lambda --scalable-dimension lambda:function:ProvisionedConcurrency --resource-id function:StockQuoteService:1 --policy-name StockQuoteServiceAutoScalingPolicy --policy-type TargetTrackingScaling --target-tracking-scaling-policy-configuration "{ \"TargetValue\": 0.7, \"PredefinedMetricSpecification\": { \"PredefinedMetricType\": \"LambdaProvisionedConcurrencyUtilization\" }}"
                       
# Output:

{
    "PolicyARN": "arn:aws:autoscaling:eu-central-1:165819210796:scalingPolicy:46fcba09-fcd4-4c1a-90bc-ba6876b94423:resource/lambda/function:StockQuoteService:1:policyName/StockQuoteServiceAutoScalingPolicy",
    "Alarms": [
        {
            "AlarmName": "TargetTracking-function:StockQuoteService:1-AlarmHigh-0bee5e99-1436-4f2a-a4bb-41f336c6c3a9",
            "AlarmARN": "arn:aws:cloudwatch:eu-central-1:165819210796:alarm:TargetTracking-function:StockQuoteService:1-AlarmHigh-0bee5e99-1436-4f2a-a4bb-41f336c6c3a9"
        },
        {
            "AlarmName": "TargetTracking-function:StockQuoteService:1-AlarmLow-49194950-b05b-4f7c-b098-d83a3dec9f7a",
            "AlarmARN": "arn:aws:cloudwatch:eu-central-1:165819210796:alarm:TargetTracking-function:StockQuoteService:1-AlarmLow-49194950-b05b-4f7c-b098-d83a3dec9f7a"
        }
    ]
}

  
# Get existing
aws application-autoscaling describe-scaling-policies --service-namespace lambda

# Remove
aws application-autoscaling delete-scaling-policy --policy-name "StockQuoteServiceAutoScalingPolicy" --resource-id function:StockQuoteService:1 --service-namespace lambda --scalable-dimension lambda:function:ProvisionedConcurrency

aws application-autoscaling deregister-scalable-target --service-namespace lambda --resource-id function:StockQuoteService:1 --scalable-dimension lambda:function:ProvisionedConcurrency
