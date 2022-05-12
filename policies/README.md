# Policies

## Dependencies

Install the latest Kyverno using:

```sh
kubectl apply -f https://raw.githubusercontent.com/kyverno/kyverno/main/config/install.yaml
```

Install Tekton pipelines using:

```
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
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