#!/bin/bash
/sbin/ethtool -G $1 rx 4077 tx 4077

offloads_fetures="rx tx sg tso ufo gso gro lro rxvlan txvlan rxhash"

for feature in $offloads_fetures
do
/sbin/ethtool -K $1 "$feature" off
done
