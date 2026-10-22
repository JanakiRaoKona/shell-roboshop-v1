#!/bin/bash

user_id=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/${0}.log"
domain_name=janakiraodevops.online
scripts_dir=$(dirname "$(realpath "$0")")

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

dnf module disable nodejs -y &>> $logs_file
dnf module enable nodejs:24 -y &>> $logs_file
dnf install nodejs -y &>> $logs_file
validate $? "Installing nodejs:24"

id roboshop &>> $logs_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    validate $? "Creating system user"
else
    echo -e "$(time_stamp) [INFO] System user roboshop is already exists...${Y}SKIPPING${N}"
fi

rm -rf /app
validate $? "remove old code"

mkdir -p /app &>> $logs_file
validate $? "Creating app directory"

curl -L -o /tmp/cart.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/cart-v4.zip &>> $logs_file
validate $? "Downloading the cart"

cd /app
unzip /tmp/cart.zip &>> $logs_file
validate $? "unzipping cart"

npm install &>> $logs_file
validate $? "Installing dependencies"

sed -i "s/DOMAIN_NAME/$domain_name/g" "$scripts_dir/cart.service"

cp "${scripts_dir}/cart.service" /etc/systemd/system/cart.service

systemctl daemon-reload &>> $logs_file
systemctl enable cart &>> $logs_file
systemctl start cart &>> $logs_file
validate $? "enable and start cart"

systemctl restart cart
validate $?  "Restarting the cart"

echo "$(time_stamp) [INFO] excution completed in seconds ${SECONDS}" | tee -a $logs_file
echo "$(time_stamp) [INFO] ==== Script completed execution ====" | tee -a $logs_file
