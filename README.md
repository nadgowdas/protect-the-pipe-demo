# Protect The Pipe! Demo Pipeline

This is a sample tekton based application build pipepline. 

> :warning: This pipeline is not intended to be used in production

Follow these instructions to setup this pipeline and run it against your sample application repository.
In this example, we are going to build and deploy [tekton-tutorial-openshift](https://github.com/IBM/tekton-tutorial-openshift) application.

You can use `minikube` to run your tekton pipeline and deploy this application.

## Install

1. Make sure you have `kubectl` configured with access to some kubernetes cluster

2. Install Tekton Pipelines:

```sh
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
```

3. Enable Tekton bundles

```sh
kubectl edit configmap feature-flags -n tekton-pipelines
```

Set `enable-tekton-oci-bundles` to `true`.

4. Install Kyverno

```sh
kubectl apply -f https://raw.githubusercontent.com/kyverno/kyverno/main/config/install.yaml
```

5. Update Kyverno permissions 

(these are needed to allow Kyverno to generate secrets, roles, etc.)

```sh
kubectl apply -f kyverno-config/
```

6. Apply Kyverno policies and common configurations managed via policies

```sh
kubectl apply -f policies/
```

7. Configure your image registry credentials. The pipeline will build and store the application image along with signature and attestations in this registry.

This command will copy your registry credentials to `img-registry-secret` in the `common` namespace, which is required for the policy that synchronizes secrets:

```sh
kubectl create secret docker-registry img-registry-secret --from-file=.dockerconfigjson=$HOME/.docker/config.json -n common
```

Alternatively, you can configure the credentials as follows:

```sh
kubectl create secret docker-registry img-registry-secret --docker-server=${SERVER} --docker-username=${USER} --docker-password=${PASSWORD} --docker-email=${EMAIL} -n run
```

8. Updated the image registry in the [signed-pipeline/run/ptp-run.yaml](signed-pipeline/run/ptp-run.yaml) from `ghcr.io/tap8stry/hello-ssf` to match your registry details.

## Usage

### Policy Tests

1. Try running a TaskRun. It will be blocked:

```sh
❯ kubectl apply -f policies/test-resources/hello-task-run.yaml
Error from server: error when creating "policies/test-resources/hello-task-run.yaml": admission webhook "validate.kyverno.svc-fail" denied the request:

resource TaskRun/default/hello-task-run was blocked due to the following policies

block-task-runs:
  check-user: Creating a TaskRun is not allowed.
require-bundle:
  check-task-run: 'validation error: a bundle is required. rule check-task-run failed
    at path /spec/taskRef/'
```

2. Try running the pipeline in the default namespace. It will be blocked:

```sh
❯ kubectl create -f signed-pipeline/run/
Error from server: error when creating "signed-pipeline/run/ptp-run.yaml": admission webhook "validate.kyverno.svc-fail" denied the request:

resource PipelineRun/default/ptp-lab-pipelinerun-scwk9 was blocked due to the following policies

require-namespaces:
  check-pipeline: 'validation error: A namespace is required. rule check-pipeline
    failed at path /metadata/namespace/'
```


### Signed Pipeline (all policies will pass)

1. Create a new namespace `run`. Kyverno will automatically add required defaults from the `common` namespace, and will generate a default network policy. The namespace will also be mutated with a `createdBy` annotation.

```sh
❯ kubectl -n run get secrets
NAME                  TYPE                                  DATA   AGE
cosign-private-key    Opaque                                1      31m
img-registry-secret   Opaque                                1      31m
kube-api-secret       kubernetes.io/service-account-token   3      31m
```

```sh
❯ kubectl -n run get role
NAME            CREATED AT
pipeline-role   2022-05-15T16:31:24Z

❯ kubectl -n run get rolebinding
NAME                    ROLE                 AGE
pipeline-role-binding   Role/pipeline-role   32m
```

```sh
❯ kubectl -n run get netpol
NAME           POD-SELECTOR   AGE
default-deny   <none>         32m
```

```sh
❯ kubectl -n run get pvc
NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
ptp-demo-pvc   Bound    pvc-c927da68-f2d1-441a-91ea-78fe444d95fd   5Gi        RWX            standard       8s
```

2. Run the signed pipeline:

```sh
kubectl create -f signed-pipeline/run/ -n run
```

3. Check the pods for status:

```sh
kubectl -n run get pods
```

4. Check policy events:

```sh
kubectl get events -A -w | grep Policy
```

5. Cleanup

```sh
kubectl -n run delete pipelineruns
kubectl delete ns run
kubectl delete ur --all -n kyverno
```

### Unsigned pipeline

1. Create a new namespace `run2`

2. Run the unsigned pipeline in `run2`

```sh
kubectl create -f unsigned-pipeline/run/ -n run2
```

This pipeline will be blocked. The policy events will show violations.

## Tekton Dashboard

To observe execution of the pipeline, consider setting up [tektoncd/dashboard](https://github.com/tektoncd/dashboard). 
The SBOM and vulnerability-report are accessible only in the task logs. 

Once successfully completed. You should be able to see your application deployed on the cluster

```bash
% kubectl get pod
NAME                                                             READY   STATUS      RESTARTS   AGE
picalc-cf9dddfdf-bnwv8                                           1/1     Running     0          59m
```
