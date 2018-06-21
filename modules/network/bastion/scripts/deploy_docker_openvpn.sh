#!/bin/bash -e
HOSTNAME=`hostname`

CLIENTNAME=openvpn
ENDPOINT_SERVER=`hostname`

docker run --user=$(id -u) -e OVPN_CN=$ENDPOINT_SERVER  -e OVPN_SERVER_URL=tcp://$ENDPOINT_SERVER:1194 -i -v $PWD:/etc/openvpn oleggorj/openvpn ovpn_initpki nopass $ENDPOINT_SERVER

docker run --user=$(id -u) -v $PWD:/etc/openvpn -ti oleggorj/openvpn easyrsa build-client-full $CLIENTNAME nopass

mkdir ~/openvpn && cd ~/openvpn && docker run --user=$(id -u) -e OVPN_DEFROUTE=1 -e OVPN_SERVER_URL=tcp://$INGRESS_IP_ADDRESS:80 -v $PWD:/etc/openvpn --rm oleggorj/openvpn ovpn_getclient $CLIENTNAME > ./${CLIENTNAME}.ovpn
