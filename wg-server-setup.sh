#!/usr/bin/env bash
set -e

# === CONFIG ===
WG_IFACE="wg0"
WG_PORT=51820
WG_NET="10.8.0.0/24"
WG_SERVER_IP="10.8.0.1/24"
# public (internet-facing) network interface, e.g. eth0, ens3, enp1s0, etc.
WAN_IFACE="$(ip route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1); exit}')"

# === PREPARE SYSTEM ===
apt update
apt install -y wireguard qrencode iptables-persistent

# Enable IP forwarding
sed -i 's/#*net.ipv4.ip_forward=.*/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sed -i 's/#*net.ipv6.conf.all.forwarding=.*/net.ipv6.conf.all.forwarding=1/' /etc/sysctl.conf
sysctl -p

# === KEYS ===
mkdir -p /etc/wireguard/clients
chmod 700 /etc/wireguard

if [ ! -f /etc/wireguard/server_privatekey ]; then
  umask 077
  wg genkey | tee /etc/wireguard/server_privatekey | wg pubkey > /etc/wireguard/server_publickey
fi

SERVER_PRIV_KEY=$(cat /etc/wireguard/server_privatekey)

# === WIREGUARD CONFIG ===
cat > /etc/wireguard/${WG_IFACE}.conf <<EOF
[Interface]
Address = ${WG_SERVER_IP}
ListenPort = ${WG_PORT}
PrivateKey = ${SERVER_PRIV_KEY}

# SaveConfig = false (we will manage via config file)
PostUp   = iptables -A FORWARD -i ${WG_IFACE} -j ACCEPT; iptables -A FORWARD -o ${WG_IFACE} -j ACCEPT; iptables -t nat -A POSTROUTING -s ${WG_NET} -o ${WAN_IFACE} -j MASQUERADE
PostDown = iptables -D FORWARD -i ${WG_IFACE} -j ACCEPT; iptables -D FORWARD -o ${WG_IFACE} -j ACCEPT; iptables -t nat -D POSTROUTING -s ${WG_NET} -o ${WAN_IFACE} -j MASQUERADE
EOF

chmod 600 /etc/wireguard/${WG_IFACE}.conf

# Persist iptables rules
iptables-save > /etc/iptables/rules.v4

# Enable & start WireGuard
systemctl enable wg-quick@${WG_IFACE}
systemctl start wg-quick@${WG_IFACE}

echo "===================================="
echo "WireGuard server setup complete."
echo "Interface: ${WG_IFACE}"
echo "VPN subnet: ${WG_NET}"
echo "Server VPN IP: ${WG_SERVER_IP}"
echo "Listening port: ${WG_PORT}"
echo "WAN interface: ${WAN_IFACE}"
echo "Now use add-wg-client.sh to create clients."
echo "===================================="
