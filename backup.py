import boto3
import datetime

def lambda_handler(event, context):
    # Set the AWS region and Jenkins instance ID
    region = 'us-east-1'
    instance_id = 'YOUR_JENKINS_INSTANCE_ID'

    # Create a timestamp for the snapshot name
    now = datetime.datetime.now()
    timestamp = now.strftime("%Y-%m-%d-%H-%M-%S")

    # Create a description for the snapshot
    description = 'Jenkins backup snapshot'

    # Create a new EBS snapshot of the Jenkins volume
    ec2 = boto3.client('ec2', region_name=region)
    response = ec2.create_snapshot(
        Description=description,
        VolumeId='YOUR_JENKINS_VOLUME_ID',
        TagSpecifications=[
            {
                'ResourceType': 'snapshot',
                'Tags': [
                    {
                        'Key': 'Name',
                        'Value': 'Jenkins backup ' + timestamp
                    },
                ]
            },
        ],
    )

    # Print the snapshot ID
    snapshot_id = response['SnapshotId']
    print('Created snapshot with ID: ' + snapshot_id)
