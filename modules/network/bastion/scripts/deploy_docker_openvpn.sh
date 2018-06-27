#!/bin/bash -e

echo "INFO: >> Start of the deployment script"

HOSTNAME=`hostname`

CLIENTNAME=openvpn
ENDPOINT_SERVER=`hostname`
INGRESS_IP_ADDRESS=`hostname`

echo "INFO: Deploying OpenVPN docker image and initializing PKIs"

docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm oleggorj/openvpn ovpn_genconfig -u udp://$ENDPOINT_SERVER

docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm -it oleggorj/openvpn ovpn_initpki

echo "INFO: Starting OpebVPN server"

docker run -v $OVPN_DATA:/etc/openvpn -d -p 1194:1194/udp --cap-add=NET_ADMIN oleggorj/openvpn

echo "INFO: Generating client certificates ($CLIENTNAME)"

docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm -it oleggorj/openvpn easyrsa build-client-full $CLIENTNAME nopass


echo "INFO: Generating OVPN file ~/${CLIENTNAME}.ovpn"

docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm oleggorj/openvpn ovpn_getclient $CLIENTNAME > ~/$CLIENTNAME.ovpn


echo "INFO: << End of the deployment script"
