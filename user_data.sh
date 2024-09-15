#!/bin/bash

LOCK_FILE="/var/lock/user-data.lock"

if [ -f "$LOCK_FILE" ]; then
    echo "User data script is already running or has completed. Exiting."
    exit 0
fi

touch "$LOCK_FILE"

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting user data script execution at $(date)"

# Function to handle errors
handle_error() {
    echo "Error occurred at line $1"
    rm "$LOCK_FILE"
    exit 1
}

# Set error handling
set -e
trap 'handle_error $LINENO' ERR

# Update system and install packages
yum update -y
yum install -y httpd awscli docker nodejs npm git java-11-amazon-corretto-devel

# Configure services
systemctl start httpd || echo "Failed to start httpd"
systemctl enable httpd || echo "Failed to enable httpd"

# Install and configure Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Add Jenkins repo and import key
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo || echo "Failed to download Jenkins repo"
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key || echo "Failed to import Jenkins key"

# Install Jenkins
yum install -y jenkins

# Enable and start Jenkins service
systemctl enable jenkins || echo "Failed to enable Jenkins"
systemctl start jenkins || echo "Failed to start Jenkins"

# Install Nginx
amazon-linux-extras install -y nginx1

# Enable and start Nginx service
systemctl enable nginx || echo "Failed to enable Nginx"
systemctl start nginx || echo "Failed to start Nginx"

# Check if firewall-cmd is available
if command -v firewall-cmd &> /dev/null; then
    # Open ports for Jenkins and Nginx in the firewall
    firewall-cmd --zone=public --add-port=8080/tcp --permanent || echo "Failed to add port 8080"
    firewall-cmd --zone=public --add-service=http --permanent || echo "Failed to add http service"
    firewall-cmd --reload || echo "Failed to reload firewall"
else
    echo "firewall-cmd not found. Skipping firewall configuration."
fi

# Deploy application to Nginx's default directory
echo "<html><h1>Welcome to Nginx on EC2</h1></html>" > /usr/share/nginx/html/index.html

# Set up web content for Apache
echo "<html><body><h1>Hello from EC2!</h1></body></html>" > /var/www/html/index.html
# Set the S3 bucket name
S3_BUCKET="app-bucket-2lz9r655"

# Download from S3
aws s3 cp s3://${S3_BUCKET}/ /home/ec2-user/ --recursive || echo "Failed to copy from S3"

# Clone repository
git clone https://github.com/Prat0487/sample-nodejs-app.git /home/ec2-user/sample-nodejs-app || echo "Failed to clone repository"

# Create and schedule backup script
cat << EOF > /home/ec2-user/backup.sh
#!/bin/bash
# Add your backup commands here
EOF
chmod +x /home/ec2-user/backup.sh
(crontab -l 2>/dev/null; echo "0 0 * * * /home/ec2-user/backup.sh") | crontab - || echo "Failed to set up cron job"

# Log instance launch
echo "EC2 instance launched successfully at $(date)" >> /var/log/ec2-launch.log

echo "User data script execution completed at $(date)"

cat << EOF > /etc/systemd/system/jenkins.service
[Unit]
Description=Jenkins Continuous Integration Server
After=network.target

[Service]
Type=notify
ExecStart=/usr/bin/jenkins
User=jenkins
Restart=on-failure
RestartSec=10
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload || echo "Failed to reload systemd"

rm "$LOCK_FILE"
touch /var/log/user-data-complete

journalctl -u httpd
journalctl -u docker
journalctl -u jenkins

# Modify the shutdown backup script
cat << EOF > /usr/local/bin/ec2-shutdown-backup.sh
#!/bin/bash
S3_BUCKET="app-bucket-2lz9r655"
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Backup important files and logs
tar czf /tmp/ec2_backup_${INSTANCE_ID}_${TIMESTAMP}.tar.gz /var/log /home/ec2-user

# Upload to S3
aws s3 cp /tmp/ec2_backup_${INSTANCE_ID}_${TIMESTAMP}.tar.gz s3://${S3_BUCKET}/

# Clean up
rm /tmp/ec2_backup_${INSTANCE_ID}_${TIMESTAMP}.tar.gz
EOF

chmod +x /usr/local/bin/ec2-shutdown-backup.sh

# Register the shutdown script
echo '/usr/local/bin/ec2-shutdown-backup.sh' >> /etc/rc.d/rc0.d/K99backup
echo '/usr/local/bin/ec2-shutdown-backup.sh' >> /etc/rc.d/rc6.d/K99backup
