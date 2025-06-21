# Sleep Prediction App - Virtual Machine Deployment Guide

## Overview
This guide will help you deploy the Sleep Prediction app to your virtual machine at IP address `20.2.139.176`.

## Prerequisites
- Virtual machine with Ubuntu/Debian Linux
- Node.js 18+ installed
- Python 3.8+ installed
- MongoDB installed and running
- Git installed

## 1. Backend Deployment

### 1.1 Clone and Setup Backend
```bash
# SSH into your VM
ssh username@20.2.139.176

# Clone the repository (if not already done)
git clone <your-repo-url>
cd sleep_prediction/backend

# Install dependencies
npm install

# Install PM2 for process management
npm install -g pm2
```

### 1.2 Configure Environment Variables
```bash
# Copy the production environment file
cp .env.production .env

# Edit the .env file with your production settings
nano .env
```

**Required .env configuration:**
```env
# Server Configuration
PORT=3000
NODE_ENV=production

# Database - Update with your MongoDB connection string
MONGODB_URI=mongodb://localhost:27017/sleepmate

# JWT Configuration - CHANGE THIS SECRET!
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_EXPIRES_IN=7d

# Email Configuration
EMAIL_SERVICE=gmail
EMAIL_USER=ssleepmate@gmail.com
EMAIL_APP_PASSWORD=vbthbeunxbshoxfr
MOCK_EMAIL=false

# ML Service Configuration
ML_SERVICE_URL=http://20.2.139.176:5000

# API Configuration
API_URL=http://20.2.139.176:3000/api

# Logging
LOG_LEVEL=info

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX=100

# CORS Configuration
CORS_ORIGIN=*
```

### 1.3 Setup ML Service
```bash
# Navigate to ML service directory
cd ml_service

# Install Python dependencies
pip install -r requirements.txt

# Set environment variable for backend URL
export BACKEND_BASE_URL=http://20.2.139.176:3000
```

### 1.4 Start Services with PM2
```bash
# Start the main backend server
pm2 start src/index.js --name "sleep-prediction-backend"

# Start the ML service
cd ml_service
pm2 start app.py --name "sleep-prediction-ml" --interpreter python3

# Save PM2 configuration
pm2 save

# Setup PM2 to start on boot
pm2 startup
```

### 1.5 Configure Firewall
```bash
# Allow HTTP and HTTPS traffic
sudo ufw allow 3000
sudo ufw allow 5000
sudo ufw allow 80
sudo ufw allow 443

# Enable firewall
sudo ufw enable
```

## 2. Flutter App Configuration

### 2.1 Update API Configuration
The Flutter app has been configured to use your VM IP address. The configuration is in `lib/config/api_config.dart`:

```dart
// Production URL - Virtual Machine deployment
static const String prodBaseUrl = 'http://20.2.139.176:3000/api';

// Set to false for production deployment
static const bool isDevelopment = false;
```

### 2.2 Build and Deploy Flutter App
```bash
# Build for Android
flutter build apk --release

# Build for iOS (if needed)
flutter build ios --release
```

## 3. Testing the Deployment

### 3.1 Test Backend Health
```bash
# Test backend health
curl http://20.2.139.176:3000/api/health

# Test ML service health
curl http://20.2.139.176:5000/health
```

### 3.2 Test API Endpoints
```bash
# Test user registration
curl -X POST http://20.2.139.176:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","name":"Test User"}'

# Test login
curl -X POST http://20.2.139.176:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

## 4. Monitoring and Logs

### 4.1 PM2 Monitoring
```bash
# View running processes
pm2 list

# View logs
pm2 logs sleep-prediction-backend
pm2 logs sleep-prediction-ml

# Monitor resources
pm2 monit
```

### 4.2 Application Logs
```bash
# Backend logs
tail -f backend/logs/app.log

# ML service logs (if using file logging)
tail -f backend/ml_service/logs/ml_service.log
```

## 5. SSL/HTTPS Setup (Recommended)

### 5.1 Install Certbot
```bash
sudo apt update
sudo apt install certbot python3-certbot-nginx
```

### 5.2 Configure Nginx
```bash
# Install Nginx
sudo apt install nginx

# Create Nginx configuration
sudo nano /etc/nginx/sites-available/sleep-prediction
```

**Nginx configuration:**
```nginx
server {
    listen 80;
    server_name 20.2.139.176;

    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    location /socket.io {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /ml {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 5.3 Enable Site and Get SSL Certificate
```bash
# Enable the site
sudo ln -s /etc/nginx/sites-available/sleep-prediction /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Get SSL certificate (if you have a domain name)
sudo certbot --nginx -d yourdomain.com
```

## 6. Troubleshooting

### 6.1 Common Issues

**Port already in use:**
```bash
# Check what's using the port
sudo netstat -tulpn | grep :3000

# Kill the process
sudo kill -9 <PID>
```

**MongoDB connection issues:**
```bash
# Check MongoDB status
sudo systemctl status mongod

# Start MongoDB if not running
sudo systemctl start mongod
```

**PM2 process not starting:**
```bash
# Check PM2 logs
pm2 logs

# Restart processes
pm2 restart all
```

### 6.2 Performance Monitoring
```bash
# Monitor system resources
htop

# Monitor network connections
netstat -tulpn

# Monitor disk usage
df -h
```

## 7. Security Considerations

1. **Change JWT Secret**: Update the JWT_SECRET in your .env file
2. **Database Security**: Use MongoDB authentication
3. **Firewall**: Only open necessary ports
4. **SSL**: Use HTTPS in production
5. **Environment Variables**: Never commit .env files to version control
6. **Regular Updates**: Keep system and dependencies updated

## 8. Backup Strategy

### 8.1 Database Backup
```bash
# Create backup script
mkdir -p /backup
nano /backup/backup.sh
```

**Backup script:**
```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
mongodump --db sleepmate --out /backup/sleepmate_$DATE
tar -czf /backup/sleepmate_$DATE.tar.gz /backup/sleepmate_$DATE
rm -rf /backup/sleepmate_$DATE
```

### 8.2 Automated Backups
```bash
# Add to crontab
crontab -e

# Add this line for daily backups at 2 AM
0 2 * * * /backup/backup.sh
```

## 9. Scaling Considerations

1. **Load Balancer**: Use Nginx as reverse proxy
2. **Database**: Consider MongoDB Atlas for managed database
3. **Caching**: Implement Redis for session storage
4. **CDN**: Use CDN for static assets
5. **Monitoring**: Implement application monitoring (e.g., New Relic, DataDog)

## Support

If you encounter any issues during deployment, check:
1. PM2 logs: `pm2 logs`
2. Application logs: `tail -f backend/logs/app.log`
3. System logs: `journalctl -u nginx`
4. Network connectivity: `ping 20.2.139.176` 