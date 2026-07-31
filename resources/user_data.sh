#!/bin/bash

# -e : exit immediately on error
# -u : treat unset variables as an error
# -x : print the commands as they get executed (so they show up in GitHub Actions logs)
set -eux


# Update system packages and install needed software
dnf update -y
dnf install -y git python39 nginx

# Where to install the app
APP_DIR=/home/ec2-user/dice

mkdir -p $APP_DIR

# Clone your application repository (replace with your repo URL)
git clone https://github.com/guilherme-ca-trindade/aws-deployment-project.git $APP_DIR

# Set the owner of the repo folder to be the user account that will ultimately run the app
chown -R ec2-user:ec2-user $APP_DIR

cd $APP_DIR
# Setup Python virtual environment and install dependencies
python3 -m venv .venv
source .venv/bin/activate
pip install -r app/requirements_flask.txt
pip install gunicorn

deactivate # Exit the Python virtual environment

# --- Create systemd service ---
cat <<EOF > /etc/systemd/system/diceapp.service
[Unit]
Description=Gunicorn service for Flask dice app
After=network.target

[Service]
User=ec2-user
Group=ec2-user
WorkingDirectory=$APP_DIR
Environment="PATH=$APP_DIR/.venv/bin"
ExecStart=$APP_DIR/.venv/bin/gunicorn -b 127.0.0.1:8000 app.flask_app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# --- Start + enable service ---
systemctl daemon-reload
systemctl enable diceapp
systemctl start diceapp


# --- Configure Nginx to reverse proxy 80 → 8000 ---
cat << 'EOF' > /etc/nginx/conf.d/myapp.conf
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

# --- Start and enable Nginx ---
systemctl enable nginx
systemctl restart nginx
