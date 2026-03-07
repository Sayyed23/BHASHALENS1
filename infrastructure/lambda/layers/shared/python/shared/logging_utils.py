"""
Shared Logging and Metrics utility
"""
import logging
import boto3
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)

cloudwatch = boto3.client('cloudwatch', region_name=os.environ.get('AWS_REGION', 'us-east-1'))

def setup_logger():
    """Returns the pre-configured logger"""
    return logger

def send_metrics(operation: str, processing_time_ms: int, success: bool, extra_metrics: dict = None) -> None:
    """Send custom metrics to CloudWatch consistently"""
    try:
        metric_data = [
            {
                'MetricName': 'ProcessingTime',
                'Value': processing_time_ms,
                'Unit': 'Milliseconds',
                'Dimensions': [
                    {'Name': 'Operation', 'Value': operation},
                    {'Name': 'Success', 'Value': str(success).lower()}
                ]
            },
            {
                'MetricName': 'RequestCount',
                'Value': 1,
                'Unit': 'Count',
                'Dimensions': [
                    {'Name': 'Operation', 'Value': operation},
                    {'Name': 'Success', 'Value': str(success).lower()}
                ]
            }
        ]
        
        if extra_metrics:
            for name, value in extra_metrics.items():
                metric_data.append({
                    'MetricName': name,
                    'Value': value,
                    'Unit': 'Milliseconds' if 'Latency' in name or 'Time' in name else 'Count',
                    'Dimensions': [{'Name': 'Operation', 'Value': operation}]
                })
        
        # Max 5 seconds target
        target_met = processing_time_ms <= 5000
        metric_data.append({
            'MetricName': 'PerformanceTargetMet',
            'Value': 1 if target_met else 0,
            'Unit': 'Count',
            'Dimensions': [{'Name': 'Operation', 'Value': operation}]
        })
        
        cloudwatch.put_metric_data(Namespace='BhashaLens', MetricData=metric_data)
        
    except Exception as e:
        logger.error(f"Error sending metrics: {str(e)}")
