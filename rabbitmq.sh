#!/bin/bash


USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$(pwd)
MONGODB_HOST=mongodb.manisrilabs.online
MYSQL_HOST=mysql.manisrilabs.online


if [ $USERID -ne 0 ]; then
    echo -e "$R You must be root to run this script."
    exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE() {

    if [ $1 -ne 0 ]; then
        echo -e "$2 installation $R failed." | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2 installed $G successfully." | tee -a $LOGS_FILE
    fi
}


cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "Adding rabbitmq.repo file"

dnf clean all &>>$LOGS_FILE
dnf makecache &>>$LOGS_FILE
VALIDATE $? "Refreshing repository metadata"

dnf install erlang rabbitmq-server -y &>>$LOGS_FILE
VALIDATE $? "Installing RabbitMQ and Erlang"

systemctl enable rabbitmq-server &>>$LOGS_FILE
VALIDATE $? "Enabling RabbitMQ"

systemctl start rabbitmq-server
VALIDATE $? "Starting RabbitMQ"

rabbitmqctl add_user roboshop roboshop123
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
VALIDATE $? "Creating rabbitmq user and setting permissions"
