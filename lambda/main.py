import os
import json
import datetime
import boto3
from urllib import request
from prettytable import PrettyTable

SLACK_WEBHOOK_URL = os.environ["SLACK_WEBHOOK_URL"]


def lambda_handler(event, context):
    x = PrettyTable()
    x.field_names = ["Service", "Amount"]
    x.align["Service"] = "l"
    x.align["Amount"] = "r"
    response = request_cost()

    amount_sum = 0
    unit = None
    max_width = 7
    services_data = []
    for group in response['ResultsByTime'][0]['Groups']:
        service = group['Keys'][0]
        amount = float(group['Metrics']['UnblendedCost']['Amount'])
        unit = group['Metrics']['UnblendedCost']['Unit']
        amount_sum += amount
        services_data.append((service, amount, unit))
        if len(service) > max_width:
            max_width = len(service)
    services_data.sort(key=lambda x: x[1], reverse=True)
    top_services = services_data[:8]
    for service, amount, unit in top_services:
        x.add_row([service, "{:.2f} {}".format(amount, unit)])

    amount_sum_str = "{:.2f} {}".format(amount_sum, unit)
    x.add_row(["-"*max_width, "-"*len(amount_sum_str)])
    x.add_row(["Total", amount_sum_str])
    table_str = x.get_string()

    start_date = response['ResultsByTime'][0]['TimePeriod']['Start']
    end_date = response['ResultsByTime'][0]['TimePeriod']['End']
    send_to_slack(f"Period: {start_date} ~ {end_date}", table_str)

    return {
        'statusCode': 200,
    }


def request_cost():
    ce = boto3.client('ce')
    today = datetime.date.today()
    first_day_of_month = datetime.date(today.year, today.month, 1)
    response = ce.get_cost_and_usage(
        TimePeriod={
            'Start': first_day_of_month.strftime('%Y-%m-%d'),
            'End': today.strftime('%Y-%m-%d'),
        },
        Granularity='MONTHLY',
        Metrics=['UnblendedCost'],
        GroupBy=[
            {
                'Type': 'DIMENSION',
                'Key': 'SERVICE'
            },
        ]
    )
    return response


def send_to_slack(pretext, cost_table):
    headers = {'Content-type': 'application/json'}
    payload = {
        "blocks": [
          {
            "type": "context",
            "elements": [
              {
                "type": "mrkdwn",
                "text": f"{pretext}\n```{cost_table}```"
              }
            ]
          }
        ]
    }
    req = request.Request(
        SLACK_WEBHOOK_URL,
        json.dumps(payload).encode(),
        headers
    )
    with request.urlopen(req) as res:
        body = res.read()
    return body
