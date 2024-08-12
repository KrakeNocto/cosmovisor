#!/bin/bash

go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.5.0

mkdir -p /root/.0gchain/cosmovisor/genesis/bin
cp /root/go/bin/0gchaind /root/.0gchain/cosmovisor/genesis/bin/
ln -s /root/.0gchain/cosmovisor/genesis /root/.0gchain/cosmovisor/current -f

source /etc/profile
cd 0g-chain
git fetch
git checkout v0.3.0.alpha.2
make install 
mkdir -p /root/.0gchain/cosmovisor/upgrades/v0.3.0/bin
cp /root/go/bin/0gchaind /root/.0gchain/cosmovisor/upgrades/v0.3.0/bin/0gchaind

sudo tee /etc/systemd/system/ogd.service > /dev/null << EOF
[Unit]
Description=0gchaind node service
After=network-online.target

[Service]
User=root
ExecStart=/root/go/bin/cosmovisor run start --home /root/.0gchain
WorkingDirectory=/root/.0gchain
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_HOME=/root/.0gchain"
Environment="DAEMON_NAME=0gchaind"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"
Environment="UNSAFE_SKIP_BACKUP=true"

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload

sudo systemctl stop ogd
cp $HOME/.0gchain/data/priv_validator_state.json $HOME/.0gchain/priv_validator_state.json.backup
rm -rf $HOME/.0gchain/data 
curl https://server-5.itrocket.net/testnet/og/og_2024-08-12_625716_snap.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.0gchain
mv $HOME/.0gchain/priv_validator_state.json.backup $HOME/.0gchain/data/priv_validator_state.json
sudo systemctl restart ogd && sudo journalctl -u ogd -f
