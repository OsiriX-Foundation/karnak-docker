# Karnak docker

This repository allows you to launch [Karnak](https://github.com/OsiriX-Foundation/karnak) with docker-compose and all its dependencies. 
This documentation is adapted to Linux operating systems.

The default url and credentials:
* Karnak URL of the user interface: http://localhost:8080
* Default Karnak user: admin
* Karnak DICOM listener port: 11112

All the Karnak's parameters can be modified in the `karnak.env` file and are described in [Environment Variables](#environment-variables).

Karnak contains third-party components:
* Postgres database for the persistence of Karnak settings 
* Redis for the cache of some values

## De-identification by profile

The principle of de-identification profile is explained [here](https://osirix-foundation.github.io/karnak-documentation/en/profiles/).

# Launch Karnak

Minimum docker version required: 20.10

1. Execute `generateSecrets.sh` to generate the secrets required by Karnak
2. Adapt all the *.env files if necessary
3. Start docker-compose with commands (or [create docker-compose service](#create-docker-compose-service)) 

## Docker commands

Commands from the root of this repository.

* Update docker images ([version](https://hub.docker.com/r/osirixfoundation/karnak/tags) defined into .env): `docker compose pull`
* Start: `docker compose up -d`
* Stop: `docker compose down`
* Stop and remove volume (reset all the data): `docker compose down -v`
* docker-compose logs: `docker compose logs -f`

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
ExecStart=/usr/local/bin/docker compose up -d
ExecStop=/usr/local/bin/docker compose down
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
* `karnak_login_password`
* `karnak_postgres_password`

## Environment Variables

To configure and analyze additional environment variables used by third-party components, please refer to the following links:
* [docker hub postgres](https://hub.docker.com/_/postgres)

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


`KARNAK_LOGIN_ADMIN`

Login used for Karnak. (optional, default is `admin`).

`KARNAK_LOGIN_PASSWORD`

Password used for Karnak. (optional, default is `undefined`).

`KARNAK_LOGIN_PASSWORD_FILE`

Password used for Karnak via file input. (alternative to `Karnak_LOGIN_PASSWORD`).

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

`KARNAK_CLINICAL_LOGS_MAX_FILE_SIZE=100MB`

Maximum file size of clinical logs. Each time the current log file reaches maxFileSize before 
the current time period ends, it will be archived with an increasing index, starting at `KARNAK_CLINICAL_LOGS_MIN_INDEX` value.

(optional, default is `100MB`).

`KARNAK_CLINICAL_LOGS_MIN_INDEX=1`

This option represents the lower bound for the window's clinical logs index. (optional, default is `1`).

`KARNAK_CLINICAL_LOGS_MAX_INDEX=10`

This option represents the upper bound for the window's clinical logs index. (optional, default is `10`).

`LOGBACK_CONFIGURATION_FILE`

Path of Logback file configuration, it will override the default log file (optional)

`IDP`

This option allow to connect identity provider. When this environment variable has the value `oidc`, the following environment variables will configure the OpenID Connect identity provider. Any other value will load the in memory user configuration. (optional, default is `undefined`).

* `OIDC_CLIENT_ID` Client id of the identity provider (optional, default is `undefined`).
* `OIDC_CLIENT_SECRET` Client secret of the identity provider (optional, default is `undefined`).
* `OIDC_ISSUER_URI` Issuer URI of the identity provider (optional, default is `undefined`).

For other environment variables of the DICOM Gateway, see this [configuration file](karnak.env).
