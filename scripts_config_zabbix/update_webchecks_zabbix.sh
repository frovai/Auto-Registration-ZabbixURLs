#!/bin/bash

URL_ZABBIX_SERVER=$URL_ZABBIX_SERVER
TOKEN=$(curl -s -X POST -H 'Content-Type: application/json-rpc' -d '{ "params": { "user": "Admin", "password": "'$ZABBIX_PASSWORD'" }, "jsonrpc": "2.0", "method": "user.login", "id": 0 }' ''$URL_ZABBIX_SERVER'' | jq '.result')
HOST_NAME_ZABBIX=URL_GROUP_WEBCHECK
LISTA_URLS=$(cat files_url/urlsIntervalUpdate.txt)


for URL_APP in ${LISTA_URLS}
do

    URL=$(echo $URL_APP | awk -F"," '{ print $1 }')
    echo $URL
    TEMPO=$(echo $URL_APP | awk -F"," '{ print $2 }')
    echo $TEMPO
    APP_NAME=$(echo $URL | sed 's/.MYDOMAIN.com.br//g')
    echo $APP_NAME

	HTTPTEST=$(curl -H "Content-Type: application/json-rpc" -X GET $URL_ZABBIX_SERVER -d'
	{
    "jsonrpc": "2.0",
    "method": "httptest.get",
    "params": {
	"output": ["name","steps"],
        "selectSteps": ["httptestid", "url"],
        "filter":{ "name": "'$APP_NAME'"}
    },
    "auth": '$TOKEN',
    "id": 0
    }' | jq '.result[]')

    ID=$(echo $HTTPTEST | jq '. | {httptestid}')
    WEB_ID=$(echo $ID | awk '{print $3}' | sed 's/"//g')
    URL=$(echo $HTTPTEST | jq '.steps')
    WEB_URL=$(echo $URL | awk '{print $6}' | sed 's/"//g')

    curl -H "Content-Type: application/json-rpc" -X GET $URL_ZABBIX_SERVER -d'
    {
        "jsonrpc": "2.0",
        "method": "httptest.update",
        "params": {
            "httptestid": '$WEB_ID',
    	    "delay": "'$TEMPO'"
        },
        "auth": '$TOKEN',
        "id": 0
    }'

done
