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

time_stamp() {
    date +"%F %T"
}

validate () {
    
    if [ $? -ne 0 ]; then 
        echo -e "$(time_stamp) [ERR] ${2}...${R}FAILED${N}" | tee -a $logs_file
        exit 1
    else
        echo -e "$(time_stamp) [INFO] ${2}...${G}SUCCESS${N}" | tee -a $logs_file
    fi
}

echo "$(time_stamp) [INFO] ==== Script started execution ====" | tee -a $logs_file

dnf module disable redis -y
dnf module enable redis:7 -y
dnf install redis -y
validate $? "Installing Redis"

sed -i -e 's/^bind 127.0.0.1/bind 0.0.0.0/' -e 's/^protected-mode yes/protected-mode no/' /etc/redis/redis.conf
validate $? "Allowing remote connections to Redis"

systemctl enable redis
systemctl start redis
validate $? "Enable & Start Redis"




