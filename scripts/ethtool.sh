#!/bin/bash
/sbin/ethtool -G eno1 rx 4077 tx 4077
/sbin/ethtool -G eno2 rx 4077 tx 4077

offloads_fetures="rx tx sg tso ufo gso gro lro rxvlan txvlan rxhash"

for feature in $offloads_fetures
do
/sbin/ethtool -K eno1 "$feature" off
done

for feature in $offloads_fetures
do
/sbin/ethtool -K eno2 "$feature" off
done
