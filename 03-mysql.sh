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

dnf module enable mysql:8.4 -y &>> $logs_file
dnf install mysql-server -y &>> $logs_file
validate $? "Installing Mysql"

systemctl enable mysqld &>> $logs_file
systemctl start mysqld &>> $logs_file
validate $? "enable & Start Mysql"

mysql_secure_installation --set-root-pass RoboShop@1 &>> $logs_file
validate $? "Setup mysql root password"





echo "$(time_stamp) [INFO] excution completed in seconds ${SECONDS}" | tee -a $logs_file
echo "$(time_stamp) [INFO] ==== Script completed execution ====" | tee -a $logs_file
