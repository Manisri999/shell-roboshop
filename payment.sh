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


dnf install python3 gcc python3-devel -y &>>$LOGS_FILE
VALIDATE $? "Installing Python3 and dependencies"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    echo "roboshop user does not exist. Creating roboshop user..."
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
    VALIDATE $? "Creating roboshop user"
else
    echo -e "roboshop user already exists. Skipping user creation... $Y SKIPPING $N"
fi

mkdir -p /app 
VALIDATE $? "Creating /app directory"

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloading payment zip file"

cd /app 
VALIDATE $? "Changing directory to /app"

rm -rf /app/* &>>$LOGS_FILE
VALIDATE $? "Removing existing files in /app"

unzip /tmp/payment.zip &>>$LOGS_FILE
VALIDATE $? "Unzipping payment zip file"


cd /app 
pip3 install -r requirements.txt &>>$LOGS_FILE
VALIDATE $? "Installing python dependencies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service
VALIDATE $? "Copying payment.service file"

systemctl daemon-reload
systemctl enable payment &>>$LOGS_FILE
systemctl start payment &>>$LOGS_FILE
VALIDATE $? "Starting AND enabling payment service"
