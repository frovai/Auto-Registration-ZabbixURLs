#!/bin/bash

URL_ZABBIX_SERVER=$URL_ZABBIX_SERVER
TOKEN=$(curl -s -X POST -H 'Content-Type: application/json-rpc' -d '{ "params": { "user": "Admin", "password": "'$ZABBIX_PASSWORD'" }, "jsonrpc": "2.0", "method": "user.login", "id": 0 }' ''$URL_ZABBIX_SERVER'' | jq '.result')
EMAIL=$CLOUDFLARE_EMAIL_ZABBIX
KEY=$CLOUDFLARE_KEY_ID
ZONE_ID=$CLOUDFLARE_ZONE_ID
LISTA_HOST=$(cat files_url/hostToDelete.txt)

for host in ${LISTA_HOST}
do
HOST_ID=$(curl -H "Content-Type: application/json-rpc" -X GET $URL_ZABBIX_SERVER -d'
{
    "jsonrpc": "2.0",
    "method": "host.get",
    "params": {
        "filter": {
            "host": [
                "'$host'"
            ]
        }
    },
    "auth": '$TOKEN',
    "id": 0
}' | jq '.result' |  sed 's/[][]//g')

HOST_ID_FORMATED=$(echo $HOST_ID | jq '.hostid')

curl -H "Content-Type: application/json-rpc" -X GET $URL_ZABBIX_SERVER -d'
{
    "jsonrpc": "2.0",
    "method": "host.delete",
    "params": [
        '$HOST_ID_FORMATED'
    ],
    "auth": '$TOKEN',
    "id": 0
}'
done
