# ArgoCD Deployment for ICS API Service

This directory contains ArgoCD Application manifests for deploying the ICS API Service to Kubernetes.

## ics-api-service Application

The `ics-api-service-application.yaml` file defines an ArgoCD Application that deploys the dev overlay of the API service.

### Configuration Details

- **Source**: Points to the `overlays/dev` directory in the `piyush76/api-services-manifest` repository
- **Destination**: Deploys to the `ics-service-dev` namespace in the same cluster where ArgoCD is running
- **Sync Policy**: 
  - Automated sync enabled
  - Prune resources that are no longer in Git
  - Self-heal to revert manual changes
  - Automatically create the namespace if it doesn't exist

## How to Apply

To deploy the API service using this ArgoCD Application, run:

```bash
kubectl apply -f argocd/ics-api-service-application.yaml
```

## Monitoring the Deployment

After applying the Application, you can monitor its status using:

```bash
kubectl get applications -n argocd
kubectl get application ics-api-service -n argocd -o jsonpath='{.status.sync.status}'
```

Or through the ArgoCD UI by navigating to the Applications page.

## Troubleshooting

If the application fails to sync, check:

1. ArgoCD can access the GitHub repository
2. The path `overlays/dev` exists in the repository
3. The Kubernetes resources in the overlay are valid

You can view detailed sync status and logs in the ArgoCD UI or using:

```bash
kubectl describe application ics-api-service -n argocd
```
