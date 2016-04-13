#!/bin/bash
# Installer for Wazuh-API daemon
# Wazuh Inc.
# April 11, 2016

I_OWNER="root"
I_GROUP="root"
I_XMODE="755"
I_FMODE="644"
I_SYSTEMD="/etc/systemd/system"
I_SYSVINIT="/etc/init.d"

OSSEC_CONF="/etc/ossec-init.conf"
DEF_OSSDIR="/var/ossec"

# Test root permissions

if [ "$USER" != "root" ]; then
    echo "Warning: Please run this script with root permissions."
fi

# Directory where OSSEC is installed

if ! [ -f $OSSEC_CONF ]; then
    echo "Can't find $OSSEC_CONF. Is OSSEC installed?"
    exit 1
fi

. $OSSEC_CONF

if [ -z "$DIRECTORY" ]; then
    DIRECTORY=$DEF_OSSDIR
fi

APP_PATH="${DIRECTORY}/api/app.js"

if ! [ -f $APP_PATH ]; then
    echo "Can't find $APP_PATH. Is Wazuh-API installed?"
    exit 1
fi

# Binary name for NodeJS

BIN_DIR=$(which nodejs 2> /dev/null)

if [ "X$BIN_DIR" = "X" ]; then
    BIN_DIR=$(which node 2> /dev/null)

    if [ "X$BIN_DIR" = "X" ]; then
        echo "NodeJS binaries not found. Is NodeJS installed?"
        exit 1
    fi
fi

# Install for systemd

if [ -n "$(ps -e | egrep ^\ *1\ .*systemd$)" ]; then
    sed "s:^ExecStart=.*:ExecStart=$BIN_DIR $APP_PATH:g" wazuh-api.service > wazuh-api.service.tmp
    install -m $I_FMODE -o $I_OWNER -g $I_GROUP wazuh-api.service.tmp $I_SYSTEMD/wazuh-api.service
    systemctl enable wazuh-api
    systemctl daemon-reload
    systemctl restart wazuh-api
    echo "Daemon installed successfully. Please check the status running:"
    echo "  systemctl status wazuh-api"

# Install for SysVinit

elif [ -n "$(ps -e | egrep ^\ *1\ .*init$)" ]; then
    sed "s:^BIN_DIR=.*:BIN_DIR=\"$BIN_DIR\":g" wazuh-api > wazuh-api.tmp
    sed -i "s:^APP_PATH=.*:APP_PATH=\"$APP_PATH\":g" wazuh-api.tmp
    install -m $I_XMODE -o $I_OWNER -g $I_GROUP wazuh-api.tmp $I_SYSVINIT/wazuh-api
    insserv wazuh-api
    service wazuh-api restart
else
    echo "Unknown init system. Exiting."
    exit 1
fi

