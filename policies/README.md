# Policies


## For Pipeline authors

1. Require ClusterTask 

2. Require a namespace for a pipeline

3. Add `securityContext` to ClusterTask

3. Generate a policy to generate the pipeline when a new "run" namespace is created

## For Pipeline users

1. Block running a bare Task

2. Require namespace for a PipelineRun 

3. Inject a default securityContext in a Task (or a PipelineRun podTemplate)

4. Generate Pipeline when a new namespace is created

5. Require all images are signed

6. Required all pipelines run YAML manifests are signed


