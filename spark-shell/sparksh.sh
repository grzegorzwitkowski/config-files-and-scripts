#!/bin/bash

SPARK_SHELL_DIR="$HOME/.sparksh-data"
CURRENT_DIR=`pwd`

PACKAGES="joda-time:joda-time:2.9.4,"
PACKAGES+="com.datastax.spark:spark-cassandra-connector_2.10:1.6.0"

cd $SPARK_SHELL_DIR

spark-shell.cmd --packages $PACKAGES

cd $CURRENT_DIR
