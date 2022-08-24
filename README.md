# Protect The Pipe! Demo Pipeline

This is a sample tekton based application build pipepline. 

> :warning: This pipeline is not intended to be used in production. Please check the [open issues](https://github.com/nadgowdas/protect-the-pipe-demo/issues) for known problems.

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

5. Apply Kyverno policies and common configurations managed via policies

```sh
kubectl apply -f policies/
```

6. Configure your image registry credentials. The pipeline will build and store the application image along with signature and attestations in this registry.

```sh
 kubectl create secret generic img-registry-secret --from-file=config.json=$HOME/.docker/config.json --type=Opaque -n common
```

**NOTE:** the secret must be created using `config.json` and `Opaque` as the type, for the pipeline to work. If you create the secret using a different command, make sure the format matches the sample [registry-secret.yaml](signed-pipeline/init/registry-secret.yaml) secret.

7. Updated the image registry in the [signed-pipeline/run/ptp-run.yaml](signed-pipeline/run/ptp-run.yaml) from `ghcr.io/tap8stry/hello-ssf` to match your registry details.

## Usage

### Signed Pipeline (all policies will pass)

1. Create a new namespace `run`:

```sh
 kubectl create ns run
```

Kyverno will automatically add required defaults from the `common` namespace, and will generate a default network policy. The namespace will also be mutated with a `createdBy` annotation.

You can check the secrets, roles, rolebinding, and network policy using the following commands:

```sh
kubectl -n run get secrets
```

```sh
NAME                  TYPE                                  DATA   AGE
cosign-private-key    Opaque                                1      31m
img-registry-secret   Opaque                                1      31m
kube-api-secret       kubernetes.io/service-account-token   3      31m
```

```sh
kubectl -n run get role
```

```sh
NAME            CREATED AT
pipeline-role   2022-05-15T16:31:24Z

❯ kubectl -n run get rolebinding
NAME                    ROLE                 AGE
pipeline-role-binding   Role/pipeline-role   32m
```

```sh
kubectl -n run get netpol
```

```sh
NAME           POD-SELECTOR   AGE
default-deny   <none>         32m
```

```sh
kubectl -n run get pvc
```

```sh
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

4. Check the build logs:

*(update the pod name to match your environment)*

```sh
❯ kubectl -n run logs -c step-build-and-push -f ptp-lab-pipelinerun-cmvvh-build-and-push-image-pod
INFO[0001] Resolved base name golang:1.12 to builder
INFO[0001] Retrieving image manifest golang:1.12
INFO[0001] Retrieving image golang:1.12 from registry index.docker.io
INFO[0002] Retrieving image manifest alpine
INFO[0002] Retrieving image alpine from registry index.docker.io
INFO[0003] Built cross stage deps: map[0:[/go/src/github.com/IBM/tekton-tutorial/picalc]]
INFO[0003] Retrieving image manifest golang:1.12
INFO[0003] Returning cached image manifest
INFO[0003] Executing 0 build triggers
INFO[0003] Unpacking rootfs as cmd COPY picalc.go picalc_test.go . requires it.
INFO[0058] WORKDIR /go/src/github.com/IBM/tekton-tutorial
INFO[0058] cmd: workdir
INFO[0058] Changed working directory to /go/src/github.com/IBM/tekton-tutorial
INFO[0058] Creating directory /go/src/github.com/IBM/tekton-tutorial
INFO[0058] Taking snapshot of files...
INFO[0058] COPY picalc.go picalc_test.go .
INFO[0058] Taking snapshot of files...
INFO[0058] RUN CGO_ENABLED=0 GOOS=linux go test
INFO[0058] Taking snapshot of full filesystem...
INFO[0066] cmd: /bin/sh
INFO[0066] args: [-c CGO_ENABLED=0 GOOS=linux go test]
INFO[0066] Running: [/bin/sh -c CGO_ENABLED=0 GOOS=linux go test]
PASS
ok      github.com/IBM/tekton-tutorial  0.060s
INFO[0092] Taking snapshot of full filesystem...
INFO[0095] RUN CGO_ENABLED=0 GOOS=linux go build -v -o picalc
INFO[0095] cmd: /bin/sh
INFO[0095] args: [-c CGO_ENABLED=0 GOOS=linux go build -v -o picalc]
INFO[0095] Running: [/bin/sh -c CGO_ENABLED=0 GOOS=linux go build -v -o picalc]
github.com/IBM/tekton-tutorial
INFO[0097] Taking snapshot of full filesystem...
INFO[0099] Saving file go/src/github.com/IBM/tekton-tutorial/picalc for later use
INFO[0099] Deleting filesystem...
INFO[0101] Retrieving image manifest alpine
INFO[0101] Returning cached image manifest
INFO[0101] Executing 0 build triggers
INFO[0101] Unpacking rootfs as cmd COPY --from=builder /go/src/github.com/IBM/tekton-tutorial/picalc /picalc requires it.
INFO[0102] COPY --from=builder /go/src/github.com/IBM/tekton-tutorial/picalc /picalc
INFO[0102] Taking snapshot of files...
INFO[0102] ENV PORT 8080
INFO[0102] CMD ["/picalc"]
INFO[0103] Pushing image to docker.io/jbugwadia/hello-ssf:1.0
INFO[0107] Pushed image to 1 destinations
```

6. Check policy events:

```sh
kubectl get events -A -w | grep Policy
```

7. Cleanup

```sh
kubectl -n run delete pipelineruns
kubectl delete ns run
```

### Unsigned pipeline

1. Create a new namespace `run2`

2. Run the unsigned pipeline in `run2`

```sh
kubectl create -f unsigned-pipeline/run/ -n run2
```

This pipeline will be blocked. The policy events will show violations.


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



## Tekton Dashboard

To observe execution of the pipeline, consider setting up [tektoncd/dashboard](https://github.com/tektoncd/dashboard). 
The SBOM and vulnerability-report are accessible only in the task logs. 

Once successfully completed. You should be able to see your application deployed on the cluster

```bash
% kubectl get pod
NAME                                                             READY   STATUS      RESTARTS   AGE
picalc-cf9dddfdf-bnwv8                                           1/1     Running     0          59m
```
