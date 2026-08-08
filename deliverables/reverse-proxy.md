# Nginx Reverse Proxy

In this setup, gunicorn runs the Flask app bound to `127.0.0.1:8000`, which means it only
accepts connections coming from the instance itself. Nginx listens on port 80 on all
interfaces and forwards ("proxies") each request to gunicorn, then passes the response back
to the client. Nginx is therefore the only thing that makes the app reachable from outside
the EC2 instance at all.

## Why do it this way

- **Port 80 without running the app as root.** Binding to ports below 1024 requires root
  privileges. Nginx handles that with a root master process that immediately drops to
  unprivileged workers, so the Flask app can keep running as the ordinary `ec2-user`
  account. If the app is ever compromised, the attacker does not get root.

- **Only the ports we intend are exposed.** The `csd215-ec2-sg` security group opens only
  22 (SSH) and 80 (HTTP). Port 8000 is never exposed, so gunicorn cannot be reached
  directly from the internet — every request has to come through nginx.

- **It protects the limited gunicorn workers.** Gunicorn is running with sync workers, and
  each one can only handle a single request at a time. Nginx buffers slow requests and slow
  responses, so a client on a bad connection ties up nginx instead of occupying a worker for
  the whole transfer.

- **The app still sees the real client.** The config sets `Host`, `X-Real-IP` and
  `X-Forwarded-For`, so the original client IP is not lost behind the proxy.

- **Separation of concerns.** Nginx is built for web-serving jobs like static files,
  compression, TLS termination and rate limiting; gunicorn just runs the Python code. Each
  piece does what it is good at.

- **Deployments are cleaner.** The CI/CD pipeline restarts the app with
  `sudo systemctl restart diceapp`, and nginx keeps holding port 80 the whole time. What is
  exposed to the internet never changes just because the app was redeployed.

## How a request flows

    browser  →  EC2 public IP :80  →  nginx  →  127.0.0.1:8000  →  gunicorn  →  Flask app
