#!/bin/bash

# Читаем IP из файла
source rabbitmq_ips.txt

# Функция для установки на одну машину
setup_rabbitmq_on_vm() {
    local VM_NAME=$1
    local VM_IP=$2
    
    echo "========================================="
    echo "Настройка RabbitMQ на $VM_NAME ($VM_IP)"
    echo "========================================="
    
    # Копируем скрипт установки на удаленную машину
    cat > /tmp/install_rabbitmq.sh << 'EOF'
#!/bin/bash

echo "Обновление системы..."
sudo apt-get update -y

echo "Установка Python 3 и pip..."
sudo apt-get install -y python3 python3-pip

echo "Установка RabbitMQ..."
sudo apt-get install -y rabbitmq-server

echo "Остановка RabbitMQ для настройки..."
sudo systemctl stop rabbitmq-server

echo "Включение плагина management..."
sudo rabbitmq-plugins enable rabbitmq_management

echo "Запуск RabbitMQ..."
sudo systemctl start rabbitmq-server
sudo systemctl enable rabbitmq-server

echo "Создание пользователя admin (при необходимости)..."
sudo rabbitmqctl add_user admin admin123 2>/dev/null || echo "Пользователь возможно уже существует"
sudo rabbitmqctl set_user_tags admin administrator
sudo rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"

echo "Установка библиотеки pika..."
pip3 install pika

echo "Проверка статуса RabbitMQ..."
sudo systemctl status rabbitmq-server --no-pager

echo "Установка завершена!"
echo "Веб-интерфейс будет доступен по адресу: http://$VM_IP:15672"
echo "Логин: admin"
echo "Пароль: admin123"
EOF

    # Копируем скрипт на удаленную машину
    scp -o StrictHostKeyChecking=no /tmp/install_rabbitmq.sh dima@$VM_IP:/tmp/
    
    # Выполняем скрипт на удаленной машине (используем sudo через ssh)
    ssh -t dima@$VM_IP "chmod +x /tmp/install_rabbitmq.sh && sudo /tmp/install_rabbitmq.sh"
    
    echo "$VM_NAME ($VM_IP) - RabbitMQ установлен и настроен"
}

# Устанавливаем на каждую машину
for vm in RabbitQL_rabbitmq-01 RabbitQL_rabbitmq-02 RabbitQL_rabbitmq-03; do
    vm_ip_var="${vm//-/_}"  # Заменяем - на _
    vm_ip="${!vm_ip_var}"
    
    if [ -n "$vm_ip" ]; then
        setup_rabbitmq_on_vm "$vm" "$vm_ip"
    else
        echo "IP адрес для $vm не найден!"
    fi
done

echo "========================================="
echo "Настройка всех машин завершена!"
echo "Проверьте доступность веб-интерфейсов:"
echo "http://<IP_машины>:15672"
