# Managing provisioned concurrency with Application Auto Scaling
# Application Auto Scaling allows you to manage provisioned concurrency on a schedule or based on utilization.
# Use a target tracking scaling policy if want your function to maintain a specified utilization percentage, 
# and scheduled scaling to increase provisioned concurrency in anticipation of peak traffic.

# Register a function's alias as a scaling target.
aws application-autoscaling register-scalable-target --service-namespace lambda --resource-id function:StockQuoteService:1 --min-capacity 1 --max-capacity 5 --scalable-dimension lambda:function:ProvisionedConcurrency
                        
# Apply a scaling policy to the target.                     
aws application-autoscaling put-scaling-policy --service-namespace lambda --scalable-dimension lambda:function:ProvisionedConcurrency --resource-id function:StockQuoteService:1 --policy-name StockQuoteServiceAutoScalingPolicy --policy-type TargetTrackingScaling --target-tracking-scaling-policy-configuration '{ "TargetValue": 0.7, "PredefinedMetricSpecification": { "PredefinedMetricType": "LambdaProvisionedConcurrencyUtilization" }}'
                       
                       
# Deregister
aws application-autoscaling deregister-scalable-target
