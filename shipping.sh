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

dnf install maven -y
VALIDATE $? "Installing maven"

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

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloading shipping zip file"

cd /app 
VALIDATE $? "Changing directory to /app"

rm -rf /app/* &>>$LOGS_FILE
VALIDATE $? "Removing existing files in /app"

unzip /tmp/shipping.zip &>>$LOGS_FILE
VALIDATE $? "Unzipping shipping zip file"


cd /app 
mvn clean package &>>$LOGS_FILE
VALIDATE $? "Building shipping service"

mv target/shipping-1.0.jar shipping.jar 
VALIDATE $? "Renaming shipping jar file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "Copying shipping.service file"


dnf install mysql -y &>>$LOGS_FILE
VALIDATE $? "Installing mysql client"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOGS_FILE
VALIDATE $? "Creating database schema"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$LOGS_FILE
VALIDATE $? "Creating application user"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOGS_FILE
VALIDATE $? "Inserting master data"


systemctl enable shipping &>>$LOGS_FILE
systemctl start shipping &>>$LOGS_FILE
VALIDATE $? "Starting AND enabling shipping service"