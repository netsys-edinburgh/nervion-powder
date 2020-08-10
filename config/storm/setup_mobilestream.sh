#!/bin/bash


# Run Redis
redis_dir="/opt/mobilestream-conext/storm/redis-5.0.2"
redis_conf="/opt/mobilestream-conext/storm/redis-5.0.2/redis.conf"
redis="redis-server"
$redis $redis_conf &


# change storm configuration file
storm_conf_dir="/opt/mobilestream-conext/storm/apache-storm-2.0.0/conf/"
storm_conf="storm.yaml"
cp $storm_conf $storm_conf_dir


# run Zookeeper
sudo rm /var/zookeeper/version-2/*
zk_dir="/opt/mobilestream-conext/storm/zookeeper-3.4.9/bin"
storm_storage_dir="/opt/mobilestream-conext/storm/storage/*"
sudo bash $zk_dir/zkServer.sh stop
sudo rm -rf $storm_storage_dir
sudo bash $zk_dir/zkServer.sh start

# run Storm
storm_dir="/opt/mobilestream-conext/storm/apache-storm-2.0.0/bin"
$storm_dir/storm nimbus &
$storm_dir/storm ui &
$storm_dir/storm supervisor &
