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

rm -rf /app  # this command is wrote for the restrict the error for unzip file when we run script multiple stime 
validate $? "remove old code"

mkdir -p /app &>> $logs_file
validate $? "Creating app directory"

curl -L -o /tmp/catalogue.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/catalogue-v4.zip &>> $logs_file
validate $? "Downloading the catalogue"

cd /app
unzip /tmp/catalogue.zip &>> $logs_file
validate $? "unzipping catalogue"

npm install &>> $logs_file
validate $? "Installing dependencies"

sed -i "s/DOMAIN_NAME/$domain_name/g" "$scripts_dir/catalogue.service"

cp "${scripts_dir}/catalogue.service" /etc/systemd/system/catalogue.service

systemctl daemon-reload &>> $logs_file
systemctl enable catalogue &>> $logs_file
systemctl start catalogue &>> $logs_file
validate $? "enable and start catalogue"

cp "$scripts_dir/mongo.repo" /etc/yum.repos.d/mongo.repo
validate $? "Adding mongo repo"

dnf install mongodb-mongosh -y &>> $logs_file
validate $? "Installing mongodb"

products_count=$(mongosh --host "mongodb.$domain_name" --quiet --eval 'db.getSiblingDB("catalogue").products.countDocuments()' 2>> $logs_file)
validate $? "Connecting mongodb"

if [ $products_count -eq 0 ]; then 
    mongosh --host "mongodb.$domain_name" </app/db/master-data.js &>> $logs_file
    validate $? "Loading products"
else 
    echo -e "$(time_stamp) [INFO] Products are already loaded...${Y}SKIPPING${N}"
fi
systemctl restart catalogue
validate $?  "Restarting the mongodb"

echo "$(time_stamp) [INFO] excution completed in seconds ${SECONDS}" | tee -a $logs_file
echo "$(time_stamp) [INFO] ==== Script completed execution ====" | tee -a $logs_file
