#!/usr/bin/env python3

import configparser
import logging
import os
import requests
import time

VERSION = '2.4.3'

##################################################################

# alerts_slack.py by Jeff Johnston <jj358mhz@gmail.com>
# THIS FILE: /usr/local/bin/pi-slack/alerts_slack.py
# No Warranty is implied, promised or permitted.

"""Provide Slack alerting for scanner listeners.

This script provides an alerting interface between a user's Broadcastify
streamer and their Slack account.

Examples:

The module contains the following functions:

- `broadcastify_request()` - Returns the response from the Broadcastify feed API.
- `slack_post(slack_payload)` - Posts the message to the Slack webhook.
- `main()` - Main executable.
"""

# *************** DO NOT ALTER BELOW ***************

_LOGGER = logging.getLogger(__name__)

# The Broadcastify API endpoint URL
BROADCASTIFY_API_URL = 'https://api.broadcastify.com/owner/?a=feed&feedId='
BROADCASTIFY_LISTEN_URL = 'https://www.broadcastify.com/listen/feed/'
BROADCASTIFY_MANAGE_URL = 'https://www.broadcastify.com/manage/feed/'
CONF_FILE = '/etc/pi-slack/pi-slack.ini'
LOGFILE_PATH = '/var/pi-slack/logs/'

# Parse user credentials from the </etc/pi-slack/pi-slack.ini> file
config = configparser.ConfigParser()
config.read(CONF_FILE)
FEED_ID = (config['CREDENTIALS']['FEED_ID'])
USERNAME = (config['CREDENTIALS']['USERNAME'])
PASSWORD = (config['CREDENTIALS']['PASSWORD'])
WEBHOOK_URL = (config['ENDPOINT']['WEBHOOK_URL'])

# *************** DO NOT ALTER ABOVE ***************


# This threshold amount is the number of listeners that need to be exceeded before Slack alerts are sent out
ALERT_THRESHOLD = 30  # ENTER YOUR DESIRED ALERT LISTENER THRESHOLD HERE

# Check whether the specified path exists
os.makedirs(LOGFILE_PATH, exist_ok=True)


def broadcastify_request():
    """Fetches the response from the Broadcastify feed API"""
    global BROADCASTIFY_API_URL, FEED_ID, USERNAME, PASSWORD

    url = BROADCASTIFY_API_URL + FEED_ID + '&type=json&u=' + USERNAME + '&p=' + PASSWORD
    data = {}  # Sets empty data dictionary

    try:
        st = time.time()
        r = requests.get(url, timeout=0.5)
        et = time.time()
        data = r.json()
        _LOGGER.debug(f'Time to execute the GET from {url} was: {(et - st) * 10 ** 3}ms')
        _LOGGER.debug(f'Broadcastify API endpoint healthy, response data is: {data}')
    except ConnectionError as error:
        _LOGGER.error(f'Broadcastify API endpoint returned error code {error}')

    return data


def slack_post(slack_payload):
    """Posts the message to the Slack webhook"""
    global WEBHOOK_URL
    # sp = requests.post(WEBHOOK_URL, data=json.dumps(slack_payload), headers={'Content-Type': 'application/json'})
    st = time.time()
    sp = requests.post(WEBHOOK_URL, json=slack_payload, headers={'Content-Type': 'application/json'}, timeout=1)
    et = time.time()
    _LOGGER.debug(f'Time to execute the POST to {sp} was: {(et - st) * 10 ** 3}ms')

    if not sp.ok:
        raise ValueError(f'Request to Slack returned an error {sp.status_code}, the response is: {sp.text}')
    _LOGGER.error(f'Request to Slack returned a {sp.status_code}, the response is: {sp.text}')

    return sp.status_code


def main():
    """Main executable"""
    global ALERT_THRESHOLD, BROADCASTIFY_LISTEN_URL, BROADCASTIFY_MANAGE_URL, FEED_ID

    # Parses the Broadcastify JSON response
    response = broadcastify_request()
    descr = response['Feed'][0]['descr']
    listeners = response['Feed'][0]['listeners']
    status = response['Feed'][0]['status']

    # Slack status message payloads
    slack_payload_feed_up = {
        'text': f'*{descr} Broadcastify Alert* :cop::fire:\n'
                f'Listener threshold *{ALERT_THRESHOLD}* exceeded, the number of listeners = *{listeners}*\n'
                f'Broadcastify status code is: {status} <healthy is 1, unhealthy is 0>\n'
                f'Listen to the feed here: <{BROADCASTIFY_LISTEN_URL}{FEED_ID}>\n'
                f'Manage the feed here: <{BROADCASTIFY_MANAGE_URL}{FEED_ID}>'
    }

    slack_payload_feed_down = {
        'text': f'*{descr} Broadcastify Alert* :ghost:\n'
                '*FEED IS DOWN*\n'
                f'Broadcastify status code is: {status} <healthy is 1, unhealthy is 0>\n'
                f'Manage the feed here: <{BROADCASTIFY_MANAGE_URL}{FEED_ID}>'
    }

    # Calls the Slack webhook for message POST
    if not status:
        slack_post(slack_payload_feed_down)
        _LOGGER.critical('Feed is down')
    else:
        if listeners >= ALERT_THRESHOLD:
            slack_post(slack_payload_feed_up)
            _LOGGER.warning(f'Listener threshold {ALERT_THRESHOLD} exceeded,\n'
                            f'the number of listeners = {listeners}, firing a Slack alert')


if __name__ == '__main__':
    logging.basicConfig(
        filename=f'{LOGFILE_PATH}pi-slack.log',
        format='%(asctime)s %(levelname)-5s %(message)s',
        level=logging.INFO,
        datefmt='%Y-%m-%d %H:%M:%S',
    )
    main()
