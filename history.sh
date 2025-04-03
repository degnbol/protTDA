#!/usr/bin/env zsh


# from instance menu list of attached block volumes
sudo iscsiadm -m node -o new -T iqn.2015-12.com.oracleiaas:b8de0d77-ee3e-4169-b1bd-b2a96069e56e -p 169.254.2.2:3260
sudo iscsiadm -m node -o update -T iqn.2015-12.com.oracleiaas:b8de0d77-ee3e-4169-b1bd-b2a96069e56e -n node.startup -v automatic
sudo iscsiadm -m node -T iqn.2015-12.com.oracleiaas:b8de0d77-ee3e-4169-b1bd-b2a96069e56e -p 169.254.2.2:3260 -l

# and again for the 32TB alphafold volume
sudo iscsiadm -m node -o new -T iqn.2015-12.com.oracleiaas:ce8376a5-48f1-4f34-97a0-326d063c5534 -p 169.254.2.3:3260
sudo iscsiadm -m node -o update -T iqn.2015-12.com.oracleiaas:ce8376a5-48f1-4f34-97a0-326d063c5534 -n node.startup -v automatic
sudo iscsiadm -m node -T iqn.2015-12.com.oracleiaas:ce8376a5-48f1-4f34-97a0-326d063c5534 -p 169.254.2.3:3260 -l

# see if the 16TB disk is sdb
sudo fdisk -l
# I formatted them before use
# Jblock64 arg was suggestion given by error when trying without
sudo mkfs.ocfs2 -Jblock64 -L PH /dev/sdb
sudo mkfs.ocfs2 -Jblock64 -L cifs /dev/sdc
sudo mkfs.ocfs2 -Jblock64 -L proteomes /dev/sdd

# mount to already existing dir
cd ~/protTDA/data/alphafold/
mkdir PH structures
# WARN: use the right device name
sudo mount /dev/sdc ./PH
sudo mount /dev/sdb ./structures
# so we don't have to sudo every command
sudo chown ubuntu PH/ PH/lost+found structures/ structures/lost+found

# fixed git pull problem with
sudo echo "nameserver 8.8.8.8\nnameserver 8.8.4.4" >> /etc/resolv.conf


