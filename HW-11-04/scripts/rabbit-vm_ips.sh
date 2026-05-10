#!/bin/bash

echo "=== Получение IP-адресов RabbitMQ машин ==="

# Получаем IP через virsh для каждой машины
for vm in RabbitQL_rabbitmq-01 RabbitQL_rabbitmq-02 RabbitQL_rabbitmq-03; do
    echo -n "$vm: "
    # Получаем MAC адрес
    MAC=$(sudo virsh domiflist "$vm" | grep -E "tap|vnet" | awk '{print $5}')
    # Ищем IP в сети vagrant-libvirt
    sudo virsh net-dhcp-leases vagrant-libvirt | grep "$MAC" | awk '{print $5}' | cut -d'/' -f1
done
