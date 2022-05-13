# Protect The Pipe! Demo Pipeline

This is a sample tekton based application build pipepline. 

> :warning: This pipeline is not intended to be used in production

Follow these instructions to setup this pipeline and run it against your sample application repository.
In this example, we are going to build and deploy [tekton-tutorial-openshift](https://github.com/IBM/tekton-tutorial-openshift) application.

You can use `minikube` to run your tekton pipeline and deploy this application.

## Getting ready

1. Make sure you have `kubectl` configured with access to some kubernetes cluster

2. Install Tekton:

```sh
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
```

3. Install Kyverno

```sh
kubectl apply -f https://raw.githubusercontent.com/kyverno/kyverno/main/config/install.yaml
```

3. Apply policies

```sh
kubectl apply -f policies/secure
kubectl apply -f policies/sign
```

## Policies 

1. **Block TaskRun**: enforces that only the Tekton controller can create TaskRun instances. Users should create a PipelineRun.

2. **Require Namespace**: PipelineRun resources should be created in a namespace for isolation and security.

3. **Generate Namespace Defaults**: Generates a default network policy and adds a `createdBy` label to each namespace

4. **Require bundle**: Bundles are required for secure pipelines. Checks PipelineRun and TaskRun for bundles.

5. **Verify Pipeline bundle signatures**: All pipeline bundles need to be signed. Pipelines should refer to bundles via digest. Bundles should contain the required in-toto attestations.

6. **Verify Task bundles signatures**: All task bundles need to be signed. Tasks should refer to bundles via digest. Bundles should contain the required in-toto attestations.

7. **Verify task.step images**: All task step images need to be signed. Steps should refer to images via digest. Images should have a vulnerability scan report.

8. **Check container security context**: check container configuration for securityContext with required settings.

## Usage

1. Try running a TaskRun. It will be blocked:

2. Try running the pipeline in the default namespace. It will be blocked.

3. Create a new namespace `run`. Kyverno will automatically add required defaults.

4. Run the signed pipeline:

```sh
kubectl -n run apply -f signed-pipeline/init/
```

5. Check the pods for status:

```sh
kubectl -n run get pods
```

6. Cleanup

```sh
kubectl -n run delete pipelineruns
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