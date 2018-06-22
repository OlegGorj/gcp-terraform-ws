#!/bin/bash -e
HOSTNAME=`hostname`

CLIENTNAME=openvpn
ENDPOINT_SERVER=`hostname`
INGRESS_IP_ADDRESS=`hostname`

echo "INFO: Deploying OpenVPN docker image and initializing PKIs"
sudo docker run --user=$(id -u) -e OVPN_CN=$ENDPOINT_SERVER  -e OVPN_SERVER_URL=tcp://$ENDPOINT_SERVER:1194 -i -v $PWD:/etc/openvpn oleggorj/openvpn ovpn_initpki nopass $ENDPOINT_SERVER

echo "INFO: Generating client configs ($CLIENTNAME)"
sudo docker run --user=$(id -u) -v $PWD:/etc/openvpn -ti oleggorj/openvpn easyrsa build-client-full $CLIENTNAME nopass

echo "INFO: Generating OVPN file ~/openvpn/${CLIENTNAME}.ovpn"
#mkdir ~/openvpn && cd ~/openvpn &&
sudo docker run --user=$(id -u) -e OVPN_DEFROUTE=1 -e OVPN_SERVER_URL=tcp://$INGRESS_IP_ADDRESS:80 -v $PWD:/etc/openvpn --rm oleggorj/openvpn ovpn_getclient $CLIENTNAME > ./${CLIENTNAME}.ovpn
