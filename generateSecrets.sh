#!/bin/bash

if [ ! -x "$(command -v docker)" ];
then
  echo "It is required to install docker"
  echo "https://docs.docker.com/install/"
  exit 1
fi

if [ ! -x "$(command -v docker-compose)" ];
then
  echo "It is required to install docker-compose"
  echo "https://docs.docker.com/compose/install/"
  exit 1
fi

secretfiles=("karnak_postgres_password" "mainzelliste_api_key" "mainzelliste_postgres_password")

secretpath="secrets/"

echo "Generate secrets"
mkdir -p "$secretpath"

docker pull osirixfoundation/openssl

for secretfile in ${secretfiles[*]}
do
  printf "%s\n" $(docker run -it osirixfoundation/openssl rand -base64 32 | tr -dc '[:print:]') > $secretpath$secretfile
done

secretfilesK=("mainzelliste_pid_k1" "mainzelliste_pid_k2" "mainzelliste_pid_k3")

for secretfileK in ${secretfilesK[*]}
do
  R=$(( $RANDOM % 100 + 1 ))
  printf "%s\n" $R > $secretpath$secretfileK
done

secretKarnakLoginPassword="karnak_login_password"
pass="ERROR"
while [ $pass != "OK" ]
do	
	read -p "Enter the web portal password: " -s firstPasswordEntry
	echo
	read -p "Confirm the password: " -s secondPasswordEntry
	echo
	if [ $firstPasswordEntry == $secondPasswordEntry ]
	then
		pass="OK"
	else
		echo "The second password does not match the first one."
	fi
done
printf "%s\n" $firstPasswordEntry > $secretpath$secretKarnakLoginPassword
echo "The password of the Karnak web portal has been defined."