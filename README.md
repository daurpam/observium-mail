# Observium+mail
This is a docker image for Observium Community Edition (v 20.9.10731) with sendmail, to include a service to send alerts.

It is based on the docker image of [somsakc](https://github.com/somsakc/docker-observium).

## Usage

Check the docker-compose.yml example file to customize your enviroment

In the label **hostname** is important include **host.domain** syntax, because sendmail will used it to identified the FDQN host, necesary for sending mails.
