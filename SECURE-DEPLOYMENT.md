# Secure Deployment Guide for ICS Service on AKS

This guide explains how to securely deploy the ICS Service API to an Azure Kubernetes Service (AKS) cluster with enhanced security measures.

## Security Concerns with LoadBalancer Service Type

Using a LoadBalancer service type directly exposes your service with a public IP address that can be accessed by anyone on the internet. This poses several security risks:

1. **Public Exposure**: Your API is directly accessible from the internet without any filtering
2. **No Authentication Layer**: No built-in authentication mechanism
3. **No TLS Termination**: Traffic might not be encrypted by default
4. **No Path-Based Routing**: Cannot restrict access to specific endpoints
5. **No Rate Limiting**: Vulnerable to DDoS attacks

## Recommended Secure Approach: ClusterIP + Ingress

A more secure approach is to use ClusterIP service type combined with a properly configured Ingress controller:

### 1. ClusterIP Service

The service.yaml already uses ClusterIP type, which only exposes the service within the cluster:

```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: ics-service
  name: ics-service
spec:
  type: ClusterIP  # More secure than LoadBalancer
  selector:
    app: ics-service
  ports:
  - name: api-port
    protocol: TCP
    port: 9090
    targetPort: 9090
  - name: actuator-port
    protocol: TCP
    port: 9091
    targetPort: 9091
```

### 2. Secure Ingress Configuration

Enhance your ingress-external.yaml with these security features:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ics-service-ingress-external
  namespace: ics-service-dev
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/rewrite-target: /$1
    nginx.ingress.kubernetes.io/use-regex: "true"
    
    # Security enhancements
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    
    # IP whitelisting - replace with your allowed IPs
    nginx.ingress.kubernetes.io/whitelist-source-range: "10.61.6.32/27,10.0.0.0/16"
    
    # Basic auth
    nginx.ingress.kubernetes.io/auth-type: "basic"
    nginx.ingress.kubernetes.io/auth-secret: "ics-basic-auth"
    nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
    
    # Rate limiting
    nginx.ingress.kubernetes.io/limit-connections: "10"
    nginx.ingress.kubernetes.io/limit-rps: "5"
spec:
  tls:
  - hosts:
    - ics-service.dev.apps.azure.incora.com
    secretName: ics-service-tls
  rules:
    - host: ics-service.dev.apps.azure.incora.com
      http:
        paths:
          - path: /chemicals/api(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: ics-service
                port:
                  number: 9090
          - path: /actuator(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: ics-service
                port:
                  number: 9091
```

### 3. Create Basic Auth Secret

Create a secret for basic authentication:

```bash
# Generate auth file with username and password
htpasswd -c auth admin secure_password

# Create Kubernetes secret
kubectl create secret generic ics-basic-auth --from-file=auth -n ics-service-dev
```

### 4. Create TLS Certificate Secret

Create a TLS certificate secret:

```bash
# Option 1: Using cert-manager (recommended for production)
# Install cert-manager and configure ClusterIssuer

# Option 2: Using self-signed certificate (for testing only)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt -subj "/CN=ics-service.dev.apps.azure.incora.com"

kubectl create secret tls ics-service-tls \
  --key tls.key --cert tls.crt -n ics-service-dev
```

## Security Benefits of This Approach

1. **IP Whitelisting**: Restricts access to specified IP ranges
2. **TLS Encryption**: Enforces HTTPS with SSL redirect
3. **Authentication**: Requires username/password authentication
4. **Rate Limiting**: Protects against DDoS attacks
5. **Host-based Routing**: Uses domain name instead of direct IP
6. **No Public IP**: Service is not directly exposed to the internet

## Deployment Steps

1. Ensure NGINX Ingress Controller is installed:
   ```bash
   # Check if NGINX Ingress Controller is installed
   kubectl get pods -n ingress-system
   
   # If not installed, install it using Helm
   helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
   helm repo update
   helm install nginx-ingress ingress-nginx/ingress-nginx \
     --namespace ingress-system --create-namespace
   ```

2. Create TLS certificate secret (see above)

3. Create basic auth secret (see above)

4. Deploy the application with secure configuration:
   ```bash
   kubectl apply -k overlays/dev
   ```

5. Access the service securely:
   ```
   https://ics-service.dev.apps.azure.incora.com/chemicals/api
   ```

## Monitoring and Troubleshooting

1. Check ingress status:
   ```bash
   kubectl get ingress -n ics-service-dev
   ```

2. Check TLS certificate:
   ```bash
   kubectl get secret ics-service-tls -n ics-service-dev
   ```

3. Check basic auth secret:
   ```bash
   kubectl get secret ics-basic-auth -n ics-service-dev
   ```

4. View ingress controller logs:
   ```bash
   kubectl logs -n ingress-system deployment/nginx-ingress-controller
   ```

By following this guide, you'll have a much more secure deployment of your ICS service on AKS.
