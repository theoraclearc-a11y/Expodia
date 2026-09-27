# Deployment Guide

This guide covers deploying Expodia to various platforms.

## Table of Contents

- [Heroku](#heroku)
- [AWS EC2](#aws-ec2)
- [AWS ECS/Fargate](#aws-ecsfargs)
- [DigitalOcean](#digitalocean)
- [Railway](#railway)
- [Render](#render)
- [Kubernetes](#kubernetes)

## Heroku

### Prerequisites
- Heroku CLI installed
- Heroku account

### Steps

1. **Login to Heroku**
   ```bash
   heroku login
   ```

2. **Create app**
   ```bash
   heroku create expodia-app
   ```

3. **Add Procfile**
   ```bash
   echo "web: npm start" > Procfile
   ```

4. **Set environment variables**
   ```bash
   heroku config:set NODE_ENV=production
   heroku config:set JWT_SECRET=your_secret_key
   heroku config:set DATABASE_URL=postgresql://user:pass@host:port/db
   ```

5. **Deploy**
   ```bash
   git push heroku main
   ```

6. **View logs**
   ```bash
   heroku logs --tail
   ```

## AWS EC2

### Prerequisites
- AWS account
- EC2 instance running Ubuntu 20.04+
- SSH access to instance

### Steps

1. **SSH into instance**
   ```bash
   ssh -i your-key.pem ubuntu@your-instance-ip
   ```

2. **Install dependencies**
   ```bash
   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
   sudo apt-get install -y nodejs
   sudo apt-get install -y postgresql postgresql-contrib
   sudo apt-get install -y nginx
   ```

3. **Clone and setup project**
   ```bash
   cd /var/www
   sudo git clone https://github.com/theoraclearc-a11y/Expodia.git
   cd Expodia
   npm install
   ```

4. **Configure environment**
   ```bash
   sudo cp .env.example .env.production
   sudo nano .env.production
   ```

5. **Build application**
   ```bash
   npm run build
   ```

6. **Setup systemd service**
   ```bash
   sudo nano /etc/systemd/system/expodia.service
   ```
   
   Add:
   ```ini
   [Unit]
   Description=Expodia Service
   After=network.target
   
   [Service]
   Type=simple
   User=www-data
   WorkingDirectory=/var/www/Expodia
   Environment="NODE_ENV=production"
   EnvironmentFile=/var/www/Expodia/.env.production
   ExecStart=/usr/bin/npm start
   Restart=always
   RestartSec=10
   
   [Install]
   WantedBy=multi-user.target
   ```

7. **Start service**
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl start expodia
   sudo systemctl enable expodia
   ```

8. **Setup Nginx reverse proxy**
   ```bash
   sudo nano /etc/nginx/sites-available/expodia
   ```
   
   Add:
   ```nginx
   server {
       listen 80;
       server_name your-domain.com;
   
       location / {
           proxy_pass http://localhost:3000;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_cache_bypass $http_upgrade;
       }
   }
   ```

9. **Enable site and restart Nginx**
   ```bash
   sudo ln -s /etc/nginx/sites-available/expodia /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl restart nginx
   ```

10. **Setup SSL with Certbot**
    ```bash
    sudo apt-get install -y certbot python3-certbot-nginx
    sudo certbot --nginx -d your-domain.com
    ```

## AWS ECS/Fargate

### Prerequisites
- AWS account
- AWS CLI configured
- ECR repository created

### Steps

1. **Build and push Docker image**
   ```bash
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin your-account-id.dkr.ecr.us-east-1.amazonaws.com
   
   docker build -t expodia:latest .
   docker tag expodia:latest your-account-id.dkr.ecr.us-east-1.amazonaws.com/expodia:latest
   docker push your-account-id.dkr.ecr.us-east-1.amazonaws.com/expodia:latest
   ```

2. **Create task definition** (AWS Console or CLI)
   ```bash
   aws ecs register-task-definition --cli-input-json file://task-definition.json
   ```

3. **Create service**
   ```bash
   aws ecs create-service --cluster expodia-cluster --service-name expodia-service --task-definition expodia:1 --desired-count 2 --launch-type FARGATE
   ```

## DigitalOcean

### Using App Platform (Recommended)

1. Connect GitHub repository
2. Select deployment source
3. Configure environment variables
4. Choose plan
5. Deploy

### Using Droplets

Similar to AWS EC2 setup above.

## Railway

### Steps

1. **Connect GitHub**
   - Go to railway.app
   - Select "Deploy from GitHub"
   - Authorize and select Expodia repo

2. **Configure services**
   - App automatically detects Node.js
   - Add PostgreSQL service
   - Add Redis service (optional)

3. **Set environment variables**
   - In Railway dashboard: Settings → Variables
   - Add .env.production variables

4. **Deploy**
   - Push to main branch
   - Railway auto-deploys

## Render

### Steps

1. **Create new Web Service**
   - Go to render.com
   - New → Web Service
   - Connect GitHub

2. **Configure**
   - Build command: `npm install && npm run build`
   - Start command: `npm start`
   - Environment: Node
   - Plan: Starter or higher

3. **Add environment variables**
   - Settings → Environment
   - Add from .env.production

4. **Create PostgreSQL database**
   - New → PostgreSQL
   - Link to service

5. **Deploy**
   ```bash
   git push  # auto-deploys
   ```

## Kubernetes

### Prerequisites
- kubectl installed
- Kubernetes cluster (EKS, GKE, AKS, etc.)
- Docker image pushed to registry

### Steps

1. **Create namespace**
   ```bash
   kubectl create namespace expodia
   ```

2. **Create ConfigMap for environment**
   ```bash
   kubectl create configmap expodia-config \
     --from-literal=NODE_ENV=production \
     --from-literal=APP_PORT=3000 \
     -n expodia
   ```

3. **Create Secrets for sensitive data**
   ```bash
   kubectl create secret generic expodia-secrets \
     --from-literal=JWT_SECRET=your_secret \
     --from-literal=DB_PASSWORD=db_password \
     -n expodia
   ```

4. **Create deployment manifest** (`k8s/deployment.yaml`)
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: expodia
     namespace: expodia
   spec:
     replicas: 3
     selector:
       matchLabels:
         app: expodia
     template:
       metadata:
         labels:
           app: expodia
       spec:
         containers:
         - name: expodia
           image: your-registry/expodia:latest
           ports:
           - containerPort: 3000
           envFrom:
           - configMapRef:
               name: expodia-config
           - secretRef:
               name: expodia-secrets
           livenessProbe:
             httpGet:
               path: /health
               port: 3000
             initialDelaySeconds: 30
             periodSeconds: 10
           readinessProbe:
             httpGet:
               path: /health
               port: 3000
             initialDelaySeconds: 5
             periodSeconds: 5
           resources:
             requests:
               memory: "256Mi"
               cpu: "250m"
             limits:
               memory: "512Mi"
               cpu: "500m"
   ```

5. **Create service**
   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: expodia-service
     namespace: expodia
   spec:
     type: LoadBalancer
     ports:
     - port: 80
       targetPort: 3000
     selector:
       app: expodia
   ```

6. **Deploy**
   ```bash
   kubectl apply -f k8s/
   ```

7. **Monitor deployment**
   ```bash
   kubectl get pods -n expodia
   kubectl logs -f deployment/expodia -n expodia
   ```

## Scaling & Auto-scaling

### Horizontal Pod Autoscaling (Kubernetes)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: expodia-hpa
  namespace: expodia
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: expodia
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

## Monitoring & Observability

### Logging
- Use centralized logging (CloudWatch, ELK, Datadog)
- Configure log level in .env files

### Metrics
- Monitor CPU, memory, disk usage
- Track application metrics (response time, errors)

### Error Tracking
- Setup Sentry: `SENTRY_DSN` in .env.production

### Health Checks
- Application exposes `/health` endpoint
- Configure liveness and readiness probes

## Post-Deployment Checklist

- [ ] Verify application is running
- [ ] Check health endpoint
- [ ] Test all critical features
- [ ] Monitor logs for errors
- [ ] Verify database connectivity
- [ ] Test payment/API integrations
- [ ] Setup SSL certificate
- [ ] Configure backup strategy
- [ ] Setup monitoring alerts
- [ ] Document access procedures
