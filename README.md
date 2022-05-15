# Protect The Pipe! Demo Pipeline

This is a sample tekton based application build pipepline. 

> :warning: This pipeline is not intended to be used in production

Follow these instructions to setup this pipeline and run it against your sample application repository.
In this example, we are going to build and deploy [tekton-tutorial-openshift](https://github.com/IBM/tekton-tutorial-openshift) application.

You can use `minikube` to run your tekton pipeline and deploy this application.

## Install

1. Make sure you have `kubectl` configured with access to some kubernetes cluster

2. Install Tekton:

```sh
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
```

3. Install Kyverno

```sh
kubectl apply -f https://raw.githubusercontent.com/kyverno/kyverno/main/config/install.yaml
```

4. Install common configuration (required for pipelines)

```sh
kubectl create ns common
 kubectl -n common apply -f signed-pipeline/init/
 ```

5. Update Kyverno permissions 

(these are needed to allow Kyverno to generate secrets, roles, etc.)

```sh
kubectl apply -f kyverno-config/
```

6. Apply Kyverno policies

```sh
kubectl apply -f policies/secure
kubectl apply -f policies/sign
```


## Usage

### Signed Pipeline (all policies will pass)

1. Try running a TaskRun. It will be blocked:

2. Try running the pipeline in the default namespace. It will be blocked.

3. Create a new namespace `run`. Kyverno will automatically add required defaults from the `common` namespace, and will generate a default network policy. The namespace will also be mutated with a `createdBy` annotation.

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

4. Run the signed pipeline:

```sh
kubectl create -f signed-pipeline/run/ -n run
```

5. Check the pods for status:

```sh
kubectl -n run get pods
```

6. Check policy events:

```sh
kubectl get events -A -w | grep Policy
```

7. Cleanup

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

## Policies 

1. **Block TaskRun**: enforces that only the Tekton controller can create TaskRun instances. Users should create a PipelineRun.

2. **Require Namespace**: PipelineRun resources should be created in a namespace for isolation and security.

3. **Generate Namespace Defaults**: Generates a default network policy and adds a `createdBy` label to each namespace

4. **Require bundle**: Bundles are required for secure pipelines. Checks PipelineRun and TaskRun for bundles.

5. **Verify Pipeline bundle signatures**: All pipeline bundles need to be signed. Pipelines should refer to bundles via digest. Bundles should contain the required in-toto attestations.

6. **Verify Task bundles signatures**: All task bundles need to be signed. Tasks should refer to bundles via digest. Bundles should contain the required in-toto attestations.

7. **Verify task.step images**: All task step images need to be signed. Steps should refer to images via digest. Images should have a vulnerability scan report.

8. **Check container security context**: check container configuration for securityContext with required settings.

## Tekton Dashboard

To observe execution of the pipeline, consider setting up [tektoncd/dashboard](https://github.com/tektoncd/dashboard). 
The SBOM and vulnerability-report are accessible only in the task logs. 

Once successfully completed. You should be able to see your application deployed on the cluster

```bash
% kubectl get pod
NAME                                                             READY   STATUS      RESTARTS   AGE
picalc-cf9dddfdf-bnwv8                                           1/1     Running     0          59m
```