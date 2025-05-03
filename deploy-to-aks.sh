set -e

echo "=== Deploying ICS Service to AKS ==="
echo "This script will deploy the ICS service with external access via both LoadBalancer and Ingress"

echo "Creating namespace ics-service-dev..."
kubectl create namespace ics-service-dev --dry-run=client -o yaml | kubectl apply -f -

echo "Applying Kustomize configuration..."
kubectl apply -k overlays/dev

echo "Applying external ingress configuration..."
kubectl apply -f overlays/dev/ingress-external.yaml

echo "Patching service to use LoadBalancer type..."
kubectl patch svc ics-service -n ics-service-dev -p '{"spec": {"type": "LoadBalancer"}}'

echo "Deployment completed. Waiting for LoadBalancer IP..."
echo "This may take a minute or two..."

timeout=60
counter=0
while [ $counter -lt $timeout ]; do
  EXTERNAL_IP=$(kubectl get svc ics-service -n ics-service-dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
  if [ -n "$EXTERNAL_IP" ]; then
    break
  fi
  echo -n "."
  sleep 5
  counter=$((counter+5))
done
echo ""

if [ -n "$EXTERNAL_IP" ]; then
  echo "✅ Service deployed successfully with LoadBalancer!"
  echo "Access the API via LoadBalancer at: http://$EXTERNAL_IP:9090/chemicals/api"
  echo "Access the actuator via LoadBalancer at: http://$EXTERNAL_IP:9091/actuator"
  
  echo "Testing API endpoint..."
  curl -s -o /dev/null -w "%{http_code}" http://$EXTERNAL_IP:9090/chemicals/api || echo "API not responding yet"
else
  echo "⚠️ LoadBalancer IP not available yet. Check status with:"
  echo "kubectl get svc ics-service -n ics-service-dev"
fi

echo "Checking Ingress status..."
INGRESS_IP=$(kubectl get ingress ics-service-ingress-external -n ics-service-dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Not available yet")

if [ "$INGRESS_IP" != "Not available yet" ]; then
  echo "✅ Ingress configured successfully!"
  echo "Access the API via Ingress at: http://$INGRESS_IP/chemicals/api"
  echo "Access the actuator via Ingress at: http://$INGRESS_IP/actuator"
else
  echo "⚠️ Ingress IP not available yet. Check status with:"
  echo "kubectl get ingress ics-service-ingress-external -n ics-service-dev"
fi

echo ""
echo "=== Deployment Summary ==="
echo "Namespace: ics-service-dev"
echo "Service: ics-service"
echo "Ingress: ics-service-ingress-external"
echo ""
echo "To check pod status: kubectl get pods -n ics-service-dev"
echo "To view pod logs: kubectl logs -n ics-service-dev deployment/ics-service"
