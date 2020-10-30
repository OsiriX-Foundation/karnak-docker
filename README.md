# Karnak docker

This repository allows you to launch [Karnak](https://github.com/OsiriX-Foundation/karnak) with docker-compose and all its dependencies. 
This documentation is adapted to Linux operating systems.

The default url and credentials:
* Karnak URL of the user interface: http://localhost:8081
* Default Karnak user: admin
* Karnak DICOM listener port: 11119

All the Karnak's parameters can be modified in the `.env` file and are described in [Environment Variables](#environment-variables).

Karnak contains third-party components:
* Postgres database for the persistence of Karnak settings 
* Mainzelliste for the management of pseudonyms

## De-identification by profile

The principle of de-identification profile is explained [here](profileExample/).

# Launch Karnak

Karnak has been tested with [docker](https://docs.docker.com/install/) **19.03** and [docker-compose](https://docs.docker.com/compose/install/) **1.22**.

1. Execute `generateSecrets.sh` to generate the secrets required by Karnak
2. Adapt all the *.env files if necessary
3. Start docker-compose with commands (or [create docker-compose service](#create-docker-compose-service)) 

## Docker commands

Commands from the root of this repository.

* Update docker images ([version](https://hub.docker.com/r/osirixfoundation/karnak/tags) defined into .env): `docker-compose pull`
* Start a docker-compose: `docker-compose up -d`
* Stop a docker-compose: `docker-compose down`
* Stop and remove volume of a docker-compose (reset all the data): `docker-compose down -v`
* docker-compose logs: `docker-compose logs -f`
* Karnak's logs: `sudo docker exec -it CONTAINERID bash`     
`cd logs`

## Create docker-compose service

Example of systemd service configuration with a docker-compose.yml file in the folder /opt/karnak (If it's another directory you have to adapt the script).

Instructions:
* Go to /etc/systemd/system
* Create the file ( eg: $ sudo touch karnak.service )
* Copy and paste the config below (eg: $ sudo nano karnak.service):

~~~
# /etc/systemd/system/karnak.service 

#########################
#    KARNAK             #
#    SERVICE            #	
##########################

[Unit]
Description=Docker Compose KARNAK Service
Requires=docker.service
After=docker.service network.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/karnak
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
~~~

Test the service:
* $ systemctl start karnak.service
* $ systemctl status karnak.service
* $ systemctl enable karnak.service

## Secrets

You can generate the secrets with the `generateSecrets.sh` script available at the root of this repository (adapt the script to your system if necessary).

Note: *These following secrets are stored in files and use the environment variables ending with _FILE (see 'Environment variables' below)*

Before starting docker-compose make sure that the secrets folder and the following secrets exist:
* `karnak_hmac_key`
* `karnak_login_password`
* `karnak_postgres_password`
* `mainzelliste_api_key`
* `mainzelliste_postgres_password`
* `mainzelliste_pid_k1`
* `mainzelliste_pid_k2`
* `mainzelliste_pid_k3`

## Environment Variables

To configure and analyze additional environment variables used by third-party components, please refer to the following links:
* [docker hub postgres](https://hub.docker.com/_/postgres)
* [docker hub mainzelliste](https://hub.docker.com/r/osirixfoundation/karnak-mainzelliste)

`DB_USER`

User of the Karnak database (optional, default is `karnak`).

`DB_USER_FILE`

User of the Karnak database via file input (alternative to `DB_USER`).

`DB_PASSWORD`

Password of the Karnak database (optional, default is `karnak`).

`DB_PASSWORD_FILE`

Password of the Karnak database via file input (alternative to `DB_PASSWORD`).

`DB_NAME`

Name of the Karnak database (optional, default is `karnak`).

`DB_NAME_FILE`

Name of the Karnak database via file input (alternative to `DB_NAME`).

`DB_HOST`

Hostname/IP Address of the PostgreSQL host. (optional, default is `localhost`).

`DB_PORT`

Port of the PostgreSQL host (optional, default is `5432`)

`MAINZELLISTE_HOSTNAME`

Hostname/IP Address of the Mainzelliste host. (optional, default is `localhost`).

`MAINZELLISTE_HTTP_PORT`

Port of the Mainzelliste host. (optional, default is `8080`).

`MAINZELLISTE_ID_TYPES`

Type of pseudonym.

`MAINZELLISTE_API_KEY`

The api key used to connect to Mainzelliste host (optional, default is `undefined`)

`KARNAK_HMAC_KEY`

The key used for the HMAC. This HMAC will be used for all the hash created by Karnak

`KARNAK_HMAC_KEY_FILE`

The key used for the HMAC via file input. (alternative to `Karnak_HMAC_KEY`).

`KARNAK_LOGIN_ADMIN`

Login used for Karnak. (optional, default is `admin`).

`KARNAK_LOGIN_PASSWORD`

Password used for Karnak. (optional, default is `undefined`).

`KARNAK_LOGIN_PASSWORD_FILE`

Password used for Karnak via file input. (alternative to `Karnak_LOGIN_PASSWORD`).

`KARNAK_WAIT_FOR`

List of service to wait before start Karnak.

`KARNAK_LOGS_MAX_FILE_SIZE`

Maximum file size of general logs. Each time the current log file reaches maxFileSize before 
the current time period ends, it will be archived with an increasing index, starting 
at `KARNAK_LOGS_MIN_INDEX` value. The maxFileSize option can be specified in bytes, kilobytes, 
megabytes or gigabytes by suffixing a numeric value with KB, MB and respectively GB. For example, 
5000000, 5000KB, 5MB and 2GB are all valid values, with the first three being equivalent.
(optional, default is `100MB`).

`KARNAK_LOGS_MIN_INDEX`

This option represents the lower bound for the window's logs index. (optional, default is `1`).

`KARNAK_LOGS_MAX_INDEX`

This option represents the upper bound for the window's logs index. (optional, default is `10`).