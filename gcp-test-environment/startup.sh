#!/bin/bash
set -x

apt-get update
apt-get install --yes software-properties-common
add-apt-repository ppa:ansible/ansible --yes
apt-get install --yes git ansible
