import boto3

# Get the service resource.
dynamodb = boto3.resource('dynamodb', endpoint_url='http://dynamodb:8000')
client = boto3.client('dynamodb', endpoint_url='http://dynamodb:8000')

keyConditionExpressions = boto3.dynamodb.conditions.Key('orb_uuid').eq(10000)
keyConditionExpressionsALL = boto3.dynamodb.conditions.Key('orb_uuid').eq(45)

# Instantiate a table resource object without actually
# creating a DynamoDB table. Note that the attributes of this table
# are lazy-loaded: a request is not made nor are the attribute
# values populated until the attributes
# on the table resource are accessed or its load() method is called.
table = dynamodb.Table('ORB_NET')
print(table.table_name)
print(table.creation_date_time)
print(table.query(KeyConditionExpression = keyConditionExpressions))

# Print out some data about the table.
# This will cause a request to be made to DynamoDB and its attribute
# values will be set based on the response.
# print(table.creation_date_time)
