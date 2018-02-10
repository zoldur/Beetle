#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

clear

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}" 
   exit 1
fi

if [ -n "$(pidof beetled)" ]; then
  echo -e "${GREEN}Beetle already running.${NC}"
  exit 1
fi

echo -e "Prepare the system to install Beetle master node."
apt-get update > /dev/null 2>&1
apt -y install software-properties-common > /dev/null 2>&1
echo -e "${GREEN}Adding bitcoin PPA repository"
apt-add-repository -y ppa:bitcoin/bitcoin > /dev/null 2>&1
apt-get update > /dev/null 2>&1
echo -e "Installing required packages, it may take some time to finish.${NC}"
apt install -y build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils libboost-all-dev libdb4.8-dev libdb4.8++-dev libminiupnpc-dev libzmq3-dev git nano tmux libgmp3-dev pwgen curl > /dev/null 2>&1
if [ "$?" -gt "0" ];
  then
    echo -e "${RED}Not all required packages were installed properly. Try to install them manually by running the following commands:${NC}\n"
    echo "apt-get update"
    echo "apt -y install software-properties-common"
    echo "apt-add-repository -y ppa:bitcoin/bitcoin"
    echo "apt-get update"
    echo "apt install -y build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils libboost-all-dev \
libdb4.8-dev libdb4.8++-dev libminiupnpc-dev libzmq3-dev git nano tmux libgmp3-dev pwgen curl"
exit 1
fi

clear
echo -e "Checking if swap space is needed."
PHYMEM=$(free -g|awk '/^Mem:/{print $2}')
if [ "$PHYMEM" -lt "2" ];
  then
    echo -e "${GREEN}Server is running with less than 2G of RAM, creating 2G swap file.${NC}"
    dd if=/dev/zero of=/swapfile bs=1024 count=2M
    chmod 600 /swapfile
    mkswap /swapfile
    swapon -a /swapfile
else
  echo -e "${GREEN}Server running with at least 2G of RAM, no swap needed.${NC}"
fi

clear
DEFAULTBEETUSER="beetle"
read -p "Beetle user: " -i $DEFAULTBEETUSER -e BEETUSER
: ${BEETUSER:=$DEFAULTBEETUSER}
useradd -m $BEETUSER >/dev/null
BEETHOME=$(sudo -H -u $BEETUSER bash -c 'echo $HOME')

echo -e "Clone git and compile it. This may take some time. Press a key to continue."
read -n 1 -s -r -p ""

git clone https://github.com/beetledev/BeetleCoin 
cd BeetleCoin/src
make -f makefile.unix
if [ "$?" -gt "0" ];
 then
  echo -e "${RED}Failed to compile beetle. Please investigate.${NC}"
  exit 1
fi
cp -a beetled /usr/local/bin
chown $BEETUSER: /usr/local/bin/beetled

clear

echo -e "${GREEN}Prepare to configure and start Beetle Masternode.${NC}"
DEFAULTBEETFOLDER="$BEETHOME/.Beetle"
read -p "Configuration folder: " -i $DEFAULTBEETFOLDER -e BEETFOLDER
: ${BEETFOLDER:=$DEFAULTBEETFOLDER}

DEFAULTBEETPORT=45823
read -p "BEET Port: " -i $DEFAULTBEETPORT -e BEETPORT
: ${BEETPORT:=$DEFAULTBEETPOR}

mkdir -p $BEETFOLDER
RPCUSER=$(pwgen -s 8 1)
RPCPASSWORD=$(pwgen -s 15 1)
cat << EOF > $BEETFOLDER/Beetle.conf
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
EOF
chown -R $BEETUSER $BEETFOLDER >/dev/null

sudo -u $BEETUSER /usr/local/bin/beetled -conf=$BEETFOLDER/Beetle.conf -datadir=$BEETFOLDER
sleep 5

if [ -z "$(pidof beetled)" ]; then
  echo -e "${RED}Beetled server couldn't start. Check /var/log/syslog for errors.{$NC}"
  exit 1
fi

BEETLEKEY=$(sudo -u $BEETUSER /usr/local/bin/beetled -conf=$BEETFOLDER/Beetle.conf -datadir=$BEETFOLDER masternode genkey)

kill $(pidof beetled)

sed -i 's/daemon=1/daemon=0/' $BEETFOLDER/Beetle.conf
NODEIP=$(curl -s4 icanhazip.com)
cat << EOF >> $BEETFOLDER/Beetle.conf
port=$BEETPORT
maxconnections=256
masternode=1
masternodeaddr=$NODEIP
masternodeprivkey=$BEETLEKEY
EOF
chown -R $BEETUSER: $BEETFOLDER >/dev/null

cat << EOF > /etc/systemd/system/beetled.service
[Unit]
Description=Beetle service
After=network.target
[Service]
ExecStart=/usr/local/bin/beetled -conf=$BEETFOLDER/Beetle.conf -datadir=$BEETFOLDER
ExecStop=/usr/local/bin/beetled -conf=$BEETFOLDER/Beetle.conf -datadir=$BEETFOLDER stop
Restart=on-abort
User=$BEETUSER
Group=root
[Install]
WantedBy=multi-user.target
EOF


FWSTATUS=$(ufw status 2>/dev/null|awk '/^Status:/{print $NF}')
if [ "$FWSTATUS" = "active" ]; then
  echo -e "Setting up firewall to allow ingress on port ${GREEN}$BEETPORT${NC}"
  ufw allow $BEETPORT/tcp comment "Beetle MN port" >/dev/null
fi

systemctl daemon-reload
systemctl start beetled.service
systemctl enable beetled.service


if [[ -z $(pidof beetled) ]]; then
  echo -e "${RED}Beetled is not running${NC}, please investigate. You should start by running the following commands:"
  echo "systemctl start beetled.service"
  echo "systemctl status beetled.service"
  echo "less /var/log/syslog"
  exit 1 
fi

echo
echo -e "======================================================================================================================="
echo -e "Beetle Masternode is up and running as user ${GREEN}$BEETUSER${NC} and it is listening on port ${GREEN}$BEETPORT${NC}." 
echo -e "Configuration file is: ${RED}$BEETFOLDER/Beetle.conf${NC}"
echo -e "MASTERNODE PRIVATEKEY is: ${RED}$BEETLEKEY${NC}"
echo -e "========================================================================================================================"

