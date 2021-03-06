#!/bin/sh
set -e

cd /tmp

if [ -f configured ]; then
	exit 0
fi

function ip_address () {
	# See: https://stackoverflow.com/a/26694162
	ip -family inet address show $1 | grep --only-matching --perl-regexp '(?<=inet\s)\d+(\.\d+){3}'
}

EXTERNAL_IP=$1

if [ "$EXTERNAL_IP" == '<unknown>' ]; then
	exit 1
fi

CONTROL_PLANE_IP=$(ip_address eth0)
DATA_PLANE_IP=$(ip_address net1)
TRUNK_IP=192.68.1.1 # CNF

cp /dev/stdin clout.yaml

cat extensions.conf.template | __=\\$ TRUNK_IP=$TRUNK_IP envsubst > extensions.conf
cat pjsip.conf.template | CONTROL_PLANE_IP=$CONTROL_PLANE_IP DATA_PLANE_IP=$DATA_PLANE_IP EXTERNAL_IP=$EXTERNAL_IP TRUNK_IP=$TRUNK_IP envsubst > pjsip.conf

mv pjsip.conf /etc/asterisk/pjsip.conf
mv rtp.conf /etc/asterisk/rtp.conf
mv extensions.conf /etc/asterisk/extensions.conf

chown asterisk:asterisk \
	/etc/asterisk/pjsip.conf \
	/etc/asterisk/rtp.conf \
	/etc/asterisk/extensions.conf

sudo asterisk -rx 'core restart now'

touch configured
