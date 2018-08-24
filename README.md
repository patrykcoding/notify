# notify

Send encrypted push notifications to simplepush app when supplied command finishes running. This project uses [simplepush API](https://simplepush.io/) to send notifications. Encrypted config file is created in order to securily store multiple keys.

## Usage

`./notify.sh <command to run>`

If the configuration file is not found, interactive setup will be run first.
