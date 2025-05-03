# Deploying ICS Service to Azure Kubernetes Service

This guide explains how to deploy the ICS Service API to an Azure Kubernetes Service (AKS) cluster with external access.

## Prerequisites

- Access to an AKS cluster
- kubectl configured to access your AKS cluster
- NGINX Ingress Controller installed on the cluster (optional, for ingress method)

## Deployment Methods

This repository includes two methods to make the API externally accessible:

1. **LoadBalancer Service Type**: Directly exposes the service with an Azure Load Balancer
2. **NGINX Ingress**: Routes traffic through the NGINX Ingress Controller

## Deployment Steps

1. Clone this repository:
   ```bash
   git clone https://github.com/piyush76/api-services-manifest.git
   cd api-services-manifest
   ```

2. Run the deployment script:
   ```bash
   ./deploy-to-aks.sh
   ```

The script will:
- Create the ics-service-dev namespace
- Apply the Kustomize configuration
- Apply the external ingress configuration
- Patch the service to use LoadBalancer type
- Display access URLs for both methods

## Accessing the API

After deployment, you can access the API through:

### LoadBalancer Method
- API Endpoint: `http://<EXTERNAL-IP>:9090/chemicals/api`
- Actuator Endpoint: `http://<EXTERNAL-IP>:9091/actuator`

### Ingress Method
- API Endpoint: `http://<INGRESS-IP>/chemicals/api`
- Actuator Endpoint: `http://<INGRESS-IP>/actuator`

## Troubleshooting

If you encounter issues:

1. Check pod status:
   ```bash
   kubectl get pods -n ics-service-dev
   ```

2. Check service status:
   ```bash
   kubectl get svc -n ics-service-dev
   ```

3. Check ingress status:
   ```bash
   kubectl get ingress -n ics-service-dev
   ```

4. View pod logs:
   ```bash
   kubectl logs -n ics-service-dev deployment/ics-service
   ```

## Network Considerations

- The AKS cluster uses Service CIDR 10.0.0.0/16
- The subnet IP range is 10.61.6.32/27
- These ranges don't overlap, so the configuration should work correctly
