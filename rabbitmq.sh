#!/bin/bash

USERID=$(id -u)

LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/rabbitmq.sh.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

if [ "$USERID" -ne 0 ]; then
    echo -e "$R You must be root to run this script. $N"
    exit 1
fi

mkdir -p "$LOGS_FOLDER"

VALIDATE() {
    if [ "$1" -ne 0 ]; then
        echo -e "$2 $R failed. $N" | tee -a "$LOGS_FILE"
        exit 1
    else
        echo -e "$2 $G successfully. $N" | tee -a "$LOGS_FILE"
    fi
}

# Copy RabbitMQ repository file
cp "$SCRIPT_DIR/rabbitmq.repo" /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "Adding rabbitmq.repo file"

# Refresh repository metadata
dnf clean all &>> "$LOGS_FILE"
VALIDATE $? "Cleaning DNF cache"

dnf makecache &>> "$LOGS_FILE"
VALIDATE $? "Refreshing repository metadata"

# Install Erlang and RabbitMQ
dnf install erlang rabbitmq-server -y &>> "$LOGS_FILE"
VALIDATE $? "Installing RabbitMQ and Erlang"

# Enable RabbitMQ service
systemctl enable rabbitmq-server &>> "$LOGS_FILE"
VALIDATE $? "Enabling RabbitMQ service"

# Start RabbitMQ service
systemctl start rabbitmq-server &>> "$LOGS_FILE"
VALIDATE $? "Starting RabbitMQ service"

# Verify RabbitMQ service
systemctl is-active --quiet rabbitmq-server
VALIDATE $? "Checking RabbitMQ service status"

# Create Roboshop user if it doesn't exist
if rabbitmqctl list_users | grep -qE '^roboshop[[:space:]]'; then
    echo -e "Roboshop user already exists. $Y SKIPPING $N" | tee -a "$LOGS_FILE"
else
    rabbitmqctl add_user roboshop roboshop123 &>> "$LOGS_FILE"
    VALIDATE $? "Creating RabbitMQ Roboshop user"
fi

# Set permissions for Roboshop user
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> "$LOGS_FILE"
VALIDATE $? "Setting RabbitMQ user permissions"

echo -e "$G RabbitMQ setup completed successfully! $N"
