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

curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloading cart zip file"

cd /app 
VALIDATE $? "Changing directory to /app"

rm -rf /app/* &>>$LOGS_FILE
VALIDATE $? "Removing existing files in /app"

unzip /tmp/cart.zip &>>$LOGS_FILE
VALIDATE $? "Unzipping cart zip file"

npm install &>>$LOGS_FILE
VALIDATE $? "Installing nodejs dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
VALIDATE $? "Copying cart.service file"

systemctl daemon-reload
systemctl enable cart  &>>$LOGS_FILE
systemctl start cart
VALIDATE $? "Starting AND enabling cart service"




