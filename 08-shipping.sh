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

dnf module enable maven:3.9 -y &>> $logs_file
dnf install maven java-25-openjdk-devel -y &>> $logs_file
validate $? "Installing Java and Maven"

alternatives --set java "/usr/lib/jvm/java-25-openjdk/bin/java"
validate "Setting java 25 as a default version"

echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f /usr/bin/java)))" > /etc/profile.d/java.sh
source /etc/profile.d/java.sh
echo $JAVA_HOME
validate $? "Setting JAVA_HOME for Maven"

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

curl -L -o /tmp/shipping.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/shipping-v4.zip &>> $logs_file
validate $? "Downloading the shipping"

cd /app
unzip /tmp/shipping.zip &>> $logs_file
validate $? "unzipping shipping"

mvn clean package &>> $logs_file
validate $? "Installing dependencies"

mv target/shipping.jar shipping.jar
validate $? "Move shipping.jar file"

dnf install mysql -y
validate $? "Installing SQL client"

# mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -pRoboShop@1 < /app/db/master-data.sql

sed -i "s/DOMAIN_NAME/$domain_name/g" "$scripts_dir/shipping.service"

cp "${scripts_dir}/shipping.service" /etc/systemd/system/shipping.service

systemctl daemon-reload &>> $logs_file
systemctl enable shipping &>> $logs_file
systemctl start shipping &>> $logs_file
validate $? "enable and start shipping"

systemctl restart shipping
validate $?  "Restarting the shipping"

echo "$(time_stamp) [INFO] excution completed in seconds ${SECONDS}" | tee -a $logs_file
echo "$(time_stamp) [INFO] ==== Script completed execution ====" | tee -a $logs_file
