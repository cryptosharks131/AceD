#!/bin/bash

TMP_FOLDER=$(mktemp -d)
CONFIG_FILE='aced.conf'
CONFIGFOLDER='/root/.acedcore'
COIN_DAEMON='/usr/local/bin/acedd'
COIN_CLI='/usr/local/bin/aced-cli'
COIN_REPO='https://github.com/Acedcoin/AceD/releases/download/v1.9_patch/v19_linux_static.tar.gz'
#SENTINEL_REPO='https://github.com/cryptosharks131/sentinel'
COIN_NAME='AceD'
#COIN_BS='bootstrap.tar.gz'

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

function update_sentinel() {
  echo -e "${GREEN}Updating sentinel.${NC}"
  cd /sentinel
  git pull
  cd -
}

function update_node() {
  echo -e "Preparing to download updated $COIN_NAME"
  rm /usr/local/bin/aced*
  rm -r ~/.acedcore/blocks/ ~/.acedcore/chainstate/ ~/.acedcore/peers.dat
  cd $TMP_FOLDER
  wget -q $COIN_REPO
  compile_error
  COIN_ZIP=$(echo $COIN_REPO | awk -F'/' '{print $NF}')
  tar xvf $COIN_ZIP --strip 1 >/dev/null 2>&1
  compile_error
  cp aced{d,-cli} /usr/local/bin
  compile_error
  strip $COIN_DAEMON $COIN_CLI
  cd - >/dev/null 2>&1
  rm -rf $TMP_FOLDER >/dev/null 2>&1
  chmod +x /usr/local/bin/acedd
  chmod +x /usr/local/bin/aced-cli
  clear
}

function compile_error() {
if [ "$?" -gt "0" ];
 then
  echo -e "${RED}Failed to compile $COIN_NAME. Please investigate.${NC}"
  exit 1
fi
}

function checks() {
if [[ $(lsb_release -d) != *16.04* ]]; then
  echo -e "${RED}You are not running Ubuntu 16.04. Installation is cancelled.${NC}"
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi
}

function prepare_system() {
echo -e "Updating the system and the ${GREEN}$COIN_NAME${NC} master node."
apt-get update >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get update > /dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq upgrade >/dev/null 2>&1
apt-get update >/dev/null 2>&1
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" make software-properties-common \
build-essential libtool autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev libboost-program-options-dev \
libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git wget curl libdb4.8-dev bsdmainutils libdb4.8++-dev \
libminiupnpc-dev unzip libgmp3-dev libzmq3-dev ufw pkg-config libevent-dev libdb5.3++>/dev/null 2>&1
if [ "$?" -gt "0" ];
  then
    echo -e "${RED}Not all required packages were installed properly. Try to install them manually by running the following commands:${NC}\n"
    echo "apt-get update"
    echo "apt-get update"
    echo "apt install -y make build-essential libtool software-properties-common autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev \
libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git curl libdb4.8-dev \
bsdmainutils libdb4.8++-dev libminiupnpc-dev libgmp3-dev libzmq3-dev ufw fail2ban pkg-config libevent-dev"
 exit 1
fi
systemctl stop $COIN_NAME.service
sleep 3
pkill -9 acedd
clear
}

function import_bootstrap() {
  rm -r ~/.acedcore/blocks ~/.acedcore/chainstate ~/.acedcore/peers.dat
  wget -q $COIN_BS
  compile_error
  COIN_ZIP=$(echo $COIN_BS | awk -F'/' '{print $NF}')
  tar -xvf $COIN_ZIP >/dev/null 2>&1
  compile_error
  cp -r ~/bootstrap/blocks ~/.acedcore/blocks
  cp -r ~/bootstrap/chainstate ~/.acedcore/chainstate
  #cp -r ~/bootstrap/peers.dat ~/.acedcore/peers.dat
  rm -r ~/bootstrap/
  rm $COIN_ZIP
  echo -e "Sync is complete"
}

function update_config() {
  sed -i '/addnode=*/d' $CONFIGFOLDER/$CONFIG_FILE
  cat << EOF >> $CONFIGFOLDER/$CONFIG_FILE
addnode=144.202.78.48:24126
addnode=107.191.44.191:24126
addnode=207.148.30.55:24126
EOF
}

function important_information() {
 $COIN_DAEMON -daemon -reindex
 sleep 15
 $COIN_CLI stop >/dev/null 2>&1
 sleep 5
 systemctl start $COIN_NAME.service
 echo
 echo -e "================================================================================================================================"
 echo -e "$COIN_NAME Masternode is updated and running again!"
 echo -e "Start: ${RED}systemctl start $COIN_NAME.service${NC}"
 echo -e "Stop: ${RED}systemctl stop $COIN_NAME.service${NC}"
 echo -e "Please check ${RED}$COIN_NAME${NC} is running with the following command: ${RED}systemctl status $COIN_NAME.service${NC}"
 echo -e "================================================================================================================================"
}

##### Main #####
clear

checks
prepare_system
update_node
#import_bootstrap
update_config
#update_sentinel
important_information
