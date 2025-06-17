# pi-slack

A lightweight Raspberry Pi integration that posts notifications or status updates to a Slack channel using an incoming webhook.

---

## 🚀 Features

- Simple Python / Bash script to send messages to Slack
- Easy configuration using environment variables or a config file
- Ideal for Raspberry Pi alerts: uptime, disk usage, custom triggers

---

## 📋 Requirements

- Raspberry Pi (any model)
- Python 3 (if using Python version)
- `requests` library (for Python)
- A Slack **Incoming Webhook URL**

---

## ⚙️ Configuration

Set your Slack webhook URL via an environment variable:

```bash
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/XXX/YYY/ZZZ"
```

Optionally, set:

```bash
export SLACK_CHANNEL="#alerts"
export SLACK_USERNAME="pi-slack"
export SLACK_EMOJI=":robot_face:"
```

---

## 📌 Usage

### Python script (e.g., `send_to_slack.py`):

```bash
./send_to_slack.py "Pi is now online!"
```

### Bash script (if applicable):

```bash
./pi-slack.sh "Disk usage is > 80% on /"
```

### Cron example (check daily):

```cron
0 8 * * * /home/pi/pi-slack/send_to_slack.py "Good morning! Pi is up and running."
```

---

## 🧪 Testing

Run the script manually to verify Slack delivery:

```bash
python3 send_to_slack.py "Test message from Pi"
```

Check your Slack channel for the message.

---

## 🧩 Example Integration

This can be used with:

- `systemd` services for offline/online alerts
- `cron` jobs monitoring disk space, CPU load, etc.
- Any automation or monitoring scripts on Raspbian

---

## 🛠️ Installation

1. Clone this repo:
   ```bash
   git clone https://github.com/jj358mhz/pi-slack.git
   cd pi-slack
   ```

2. Install dependencies:
   ```bash
   pip3 install requests
   ```

3. Make scripts executable:
   ```bash
   chmod +x *.py
   ```

4. Configure Slack webhook and optional env vars.

---

## 🧾 Environment Variables

| Variable             | Description                              | Default             |
|----------------------|------------------------------------------|---------------------|
| `SLACK_WEBHOOK_URL`  | Incoming webhook URL (required)          | —                   |
| `SLACK_CHANNEL`      | Slack channel (e.g., `#alerts`)          | `#general`          |
| `SLACK_USERNAME`     | Display name for the message bot         | `pi-slack`          |
| `SLACK_EMOJI`        | Bot icon (e.g., `:robot_face:`)          | `:robot_face:`      |

---

## 🚧 Troubleshooting

- **No message?** Check that the webhook URL is correctly exported and reachable.
- **Permission denied?** Ensure the script has execute permission:  
  ```bash
  chmod +x send_to_slack.py
  ```

---

## 📄 License

Open-source, available under the MIT License. See `LICENSE` for details.

---

## ✒️ Author

Jeff Johnston · Homebody  
Contact: <jj358mhz@gmail.com>

---

## 📢 Contributions

Feel free to:

- Report issues
- Suggest enhancements
- Submit PRs for improvements

---

# Thank you for using pi-slack! 🛰️
