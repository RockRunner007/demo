import json
import boto3
import twitchirc 
import twilio
from botocore.exceptions import ClientError

s3 = boto3.client('s3')

def lambda_handler(event, context):

    try: 
        response = s3.put_object(
                Body=b'incoming!',
                Bucket='arn:aws:s3::{account}:accesspoint/muyuekhu5pmn5.mrap',
                Key='accesspoint/incoming.txt'
                )
        return {
            'statusCode': 200,
            'body': json.dumps(response)
        }
    except ClientError as error:
        raise error