# Nginx Reverse Proxy

Nginx is used here as a reverse proxy to forward incoming HTTP traffic from port 80 to the Flask application running locally on port 8000.

The setup is useful because:
- it allows the web server to receive traffic on a standard port
- it keeps the Flask app running in the background as a service
- it helps separate web serving concerns from the application logic
- it makes the deployment cleaner and easier to manage

Using nginx as a reverse proxy improves reliability. And AWS is essential here it provides the cloud infrastructure to host our app and making it reachable on the internet, no needing any longer to run locally on the machine. Therefore, AWS handles the infrastructure and our project focus on deplying the app. So the connection happens as:
- AWS provides the server environment
- nginx handles web requests
- our app runs behind nginx on that AWS server