#!/bin/bash

# Запрашиваем пароль у пользователя
read -s -p "Введите пароль для sudo: " SUDO_PASSWORD
echo

# Переходим в нужную директорию
cd ~/srsRAN_4G/build || { echo "Не удалось перейти в директорию ~/srsRAN_4G/build"; exit 1; }

# Открываем 5 терминалов и выполняем команды в каждом из них
gnome-terminal -- bash -c "echo $SUDO_PASSWORD | sudo -S ip netns add ue1; exec bash"
sleep 3
gnome-terminal -- bash -c "echo $SUDO_PASSWORD | sudo -S ./srsepc/src/srsepc; exec bash"
sleep 3
gnome-terminal -- bash -c "echo $SUDO_PASSWORD | sudo -S ./srsenb/src/srsenb --rf.device_name=zmq --rf.device_args='fail_on_disconnect=true,tx_port=tcp://*:2000,rx_port=tcp://localhost:2001,id=enb,base_srate=23.04e6'; exec bash"
sleep 3
gnome-terminal -- bash -c "echo $SUDO_PASSWORD | sudo -S ./srsue/src/srsue --rf.device_name=zmq --rf.device_args='tx_port=tcp://*:2001,rx_port=tcp://localhost:2000,id=ue,base_srate=23.04e6' --gw.netns=ue1 --log.all_level=debug; exec bash"
