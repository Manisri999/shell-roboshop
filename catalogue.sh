#!/bin/bash


USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$(pwd)
MONGODB_HOST=mongodb.daws88s.online


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

dnf module disable nodejs -y &>>$LOGS_FILE
VALIDATE $? "Disabling nodejs module"

dnf module enable nodejs:20 -y &>>$LOGS_FILE
VALIDATE $? "Enabling nodejs:20 module"

dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "Installing nodejs"

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

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloading catalogue zip file"

cd /app 
VALIDATE $? "Changing directory to /app"

rm -rf /app/* &>>$LOGS_FILE
VALIDATE $? "Removing existing files in /app"

unzip /tmp/catalogue.zip &>>$LOGS_FILE
VALIDATE $? "Unzipping catalogue zip file"

npm install &>>$LOGS_FILE
VALIDATE $? "Installing nodejs dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying catalogue.service file"

systemctl daemon-reload
systemctl enable catalogue  &>>$LOGS_FILE
systemctl start catalogue
VALIDATE $? "Starting AND enabling catalogue service"


cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying mongodb.repo file"

dnf install mongodb-mongosh -y &>>$LOGS_FILE
VALIDATE $? "Installing mongodb-mongosh"

INDEX=$(mongosh --host $MONGODB_HOST --quiet --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js
    VALIDATE $? "Loading catalogue schema"
else
    echo -e "catalogue schema already exists. Skipping schema load... $Y SKIPPING $N"
fi

systemctl restart catalogue
VALIDATE $? "Restarting catalogue service"


