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


dnf module disable nginx -y &>>$LOGS_FILE
dnf module enable nginx:1.24 -y &>>$LOGS_FILE
dnf install nginx -y &>>$LOGS_FILE
VALIDATE $? "Installing nginx"

systemctl enable nginx &>>$LOGS_FILE
systemctl start nginx &>>$LOGS_FILE
VALIDATE $? "enable and started nginx service"

rm -rf /usr/share/nginx/html/* 
VALIDATE $? "Removing default nginx content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
cd /usr/share/nginx/html 
unzip /tmp/frontend.zip 
VALIDATE $? "Unzipping frontend content"

rm -rf /etc/nginx/nginx.conf

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copied our nginx conf file"

systemctl restart nginx 
VALIDATE $? "Restarting nginx service"
