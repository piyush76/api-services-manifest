set -e

kubectl create namespace ics-service-dev --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -k overlays/dev

kubectl apply -f overlays/dev/ingress-external.yaml

kubectl patch svc ics-service -n ics-service-dev -p '{"spec": {"type": "LoadBalancer"}}'

echo "Deployment completed. Waiting for LoadBalancer IP..."
sleep 10

EXTERNAL_IP=$(kubectl get svc ics-service -n ics-service-dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Service deployed successfully!"
echo "Access the API via LoadBalancer at: http://$EXTERNAL_IP:9090/chemicals/api"
echo "Access the actuator via LoadBalancer at: http://$EXTERNAL_IP:9091/actuator"

INGRESS_IP=$(kubectl get ingress ics-service-ingress-external -n ics-service-dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Not available yet")

if [ "$INGRESS_IP" != "Not available yet" ]; then
  echo "Access the API via Ingress at: http://$INGRESS_IP/chemicals/api"
  echo "Access the actuator via Ingress at: http://$INGRESS_IP/actuator"
fi
