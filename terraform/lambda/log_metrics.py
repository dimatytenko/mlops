import json


def lambda_handler(event, context):
    message = "Logging metrics..."
    print(message)
    return {
        "status": "logged",
        "detail": message,
        "input": event,
    }
