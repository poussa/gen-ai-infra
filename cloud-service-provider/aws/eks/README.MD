# OPEA applications AWS EKS deployment guide

This guide shows how to deploy OPEA applications on Amazon Web Service (AWS) Elastic Kubernetes Service (EKS) using Terraform.

## Prerequisites

- Access to AWS EKS
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli), [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and [Helm](https://helm.sh/docs/helm/helm_install/) installed on your local machine.

## Setup

Initialize the Terraform environment.

```bash
terraform init
```

## Create EKS cluster

By default, 1-node EKS cluster is created which suitable for running an OPEA application. See `variables.tf` and `opea-<application-name>.tfvars` if you want to tune the EKS cluster properties, e.g., number of nodes, instance types or disk size.

## Create Persistent Volume Claim

OPEA needs a volume where to store the model. For that we need to create Kubernetes Persistent Volume Claim (PVC). OPEA requires `ReadWriteMany` option since multiple pods needs access to the storage and they can be on different nodes. On EKS, only EFS supports `ReadWriteMany`. Ensure `<namespace>` below matches the namespace you deploy the application to.

```bash
kubectl apply -f eks-efs-csi-pvc.yaml -n <namescape>
```

### ChatQnA

Use the commands below to create EKS cluster.

```bash
terraform plan --var-file opea-chatqna.tfvars -out opea-chatqna.plan
terraform apply "opea-chatqna.plan"
```

Once the cluster is ready, get the kubeconfig file to access the new cluster. By default, the command updates the `~/.kube/config`. If you want dedicated kubeconfig file, set the `KUBECONFIG` environment variable prior executing the command (e.g., `export KUBECONFIG=~/.kube/aws-opea.conf`)

```bash
aws eks update-kubeconfig --name opea-chatqna
```

Now your should have access to the cluster via `kubectl` command.

Deploy ChatQnA Application

```bash
helm install -n chatqna --create-namespace chatqna --set service.type=LoadBalancer --set global.modelUsePVC=model-volume --set global.HUGGINGFACEHUB_API_TOKEN=${HFTOKEN} ../../../helm-charts/chatqna
```

After a while, the OPEA application should be running. You can check the status via kubectl.

```bash 
kubectl get pod -n chatqna
```

You can now start using the OPEA application.

```bash
OPEA_SERVICE=$(kubectl get svc -n chatqna chatqna -ojsonpath=".status.LoadBalancer.ip[0]")
curl http://${OPEA_SERVICE}:8888/v1/chatqna \
    -H "Content-Type: application/json" \
    -d '{"messages": "What is the revenue of Nike in 2023?"}'
```

Cleanup

Delete the cluster via the following command.

```bash
terraform destroy
```

