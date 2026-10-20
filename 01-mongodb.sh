#!/bin/bash

user_id=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/${0}.log"

if [ $user_id -ne 0 ]; then
    echo "Please run this script with sudo access..."
    exit 1
fi

mkdir -p "${logs_folder}"

echo "Script exection starting time $(date +"%F %T")" &>> $logs_file

validate () {
    
    if [ $? -ne 0 ]; then 
        echo -e "${2}...${R}FAILED${N}" | tee -a $logs_file
        exit 1
    else
        echo -e "${2}...${G}SUCCESS${N}" | tee -a $logs_file
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo 
validate $? "Adding mongo repo"

dnf install mongodb-org -y &>> $logs_file
validate $? "Install mongodb"

systemctl enable mongod &>> $logs_file
systemctl start mongod &>> $logs_file
validate $? "enable & start mongodb"

sed -i "s/127.0.0.1/0.0.0.0/g" /etc/mongod.conf
validate $? "Updating remote connections to mongodb"

systemctl restart mongod
validate $? "restart mongodb"
