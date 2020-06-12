#!/bin/bash

if [ ! -x "$(command -v docker)" ];
then
  echo "You must install docker"
  echo "https://docs.docker.com/install/"
  exit 1
fi

if [ ! -x "$(command -v docker-compose)" ];
then
  echo "You must install docker-compose"
  echo "https://docs.docker.com/compose/install/"
  exit 1
fi

secretfiles=("karnak_hmac_key" "karnak_postgres_password" \
  "mainzelliste_api_key" "mainzelliste_postgres_password")

secretpath="secrets/"

echo "Generate secrets"
if [[ ! -d "$secretpath" ]]
then
  mkdir $secretpath
fi

docker pull osirixfoundation/openssl

for secretfile in ${secretfiles[*]}
do
  printf "%s\n" $(docker run -it osirixfoundation/openssl rand -base64 32 | tr -dc '[:print:]') > $secretpath$secretfile
done

secretfilesK=("mainzelliste_pid_k1" "mainzelliste_pid_k2" \
  "mainzelliste_pid_k3")

for secretfileK in ${secretfilesK[*]}
do
  R=$(( $RANDOM % 100 + 1 ))
  printf "%s\n" $R > $secretpath$secretfileK
done

docker-compose pull && docker-compose up