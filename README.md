# Beetle
Shell script to install a [Beetle Masternode](https://beetlecoin.io) on a Linux server running Ubuntu 16.04. Use it on your own risk.  
This script will install Beetlecoin version 2.1.3.1 and re-sync it from scratch using bootstrap.dat

***
## Installation or update::
```
wget -N https://raw.githubusercontent.com/zoldur/Beetle/master/beetle_install.sh
bash beetle_install.sh
```
***

## Desktop wallet setup

After the MN is up and running, you need to configure the desktop wallet accordingly. Here are the steps:
1. Open the Beetle Desktop Wallet.
2. Go to RECEIVE and create a New Address: **MN1**
3. Send **10000** **50000*** or **150000** BEET to **MN1**. You need to send all coins in one single transaction.
4. Wait for 15 confirmations.
5. Go to **Help -> "Debug Window - Console"**
6. Type the following command: **masternode outputs**
7. Go to  ** Tools -> "Open Masternode Configuration File"
8. Add the following entry:
```
Alias Address Privkey TxHash Output_index
```
* Alias: **MN1**
* Address: **VPS_IP:PORT**
* Privkey: **Masternode Private Key**
* TxHash: **First value from Step 6**
* Output index:  **Second value from Step 6** It can be **0** or **1**
9. Click OK and exit the Wallet.
10. Open Beetle Wallet, go to **Masternode Tab**. If you tab is not shown, please enable it from: **Settings - Options - Wallet - Show Masternodes Tab**
11. Select your MN and click on **Start Alias**
12. Login to your VPS and check your masternode status by running the following command. If you get **Masternode started successfully**, it means your masternode is active.
```
beetlecoin-cli masternode status
```
***

## Usage:
```
beetlecoin-cli mnsync status
beetlecoin-cli masternode status #This will tell you if the masternode is running
beetlecoin-cli getinfo
```
Also, if you want to check/start/stop **Beetle**, run one of the following commands as **root**:

```
systemctl status Beetle #To check if Beetle service is running
systemctl start Beetle #To start Beetle service
systemctl stop Beetle #To stop Beetle service
systemctl is-enabled Beetle #To check if Beetle service is enabled on boot
```
***


## Donations

Any donation is highly appreciated

**BEET**: XPF1wS8XKF92brF6aMyCSBv55E2gnqVTLD  
**BTC**: 3MQLEcHXVvxpmwbB811qiC1c6g21ZKa7Jh  
**ETH**: 0x26B9dDa0616FE0759273D651e77Fe7dd7751E01E  
**LTC**: LNZpK4rCd1JVSB3rGKTAnTkudV9So9zexB  

