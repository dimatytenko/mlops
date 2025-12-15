import json


def lambda_handler(event, context):
    message = "Validating data..."
    print(message)
    return {
        "status": "validated",
        "detail": message,
        "input": event,
    }
