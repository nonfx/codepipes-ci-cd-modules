## Container Image loader

This script pulls container images from one registry (say DockerHub) and pushes them up to 1 or more other registries (likely CldCvr registries on cloud). This is so that we can have local hosting of images in our cloud accounts.

The script processes a manifest file - container-manifest.yaml - This contains the list of registries to push to (ECR/GCR) and the images to process. e.g.:

```
registries:
  - public.ecr.aws/p0k3r4s4
  - us-docker.pkg.dev/codepipes-staging/ci-cd

images:
  - name: sonarsource/sonar-scanner-cli
    tags: [latest, 4, 4.8]
    target_name: sonar-scanner-cli
```

This will push the DockerHub image sonar-scanner-cli up to ECR and GCR (Artifact Registry) with tag latest, 4 and 4.8.

Requirements:

- yq needs to be installed (https://github.com/mikefarah/yq/#install)
- You need to be signed into all registries listed in the manifest file and have write permissions to them.
- For AWS ECR, the image repo needs to be pre-created (can use AWS console)
- If you want to avoid any rate limit issues, you should sign into DH as well

Running the script:

```
$ scripts/container-load> ./container-load.sh
```

There is also a make target for ease of use:

```
$ make push-module-containers
```

The make target will also attempt to login to ECR and GCR using local credentials.
NOTE: This make target will fail with a message if not run from an environment based of amd64 CPU architecture.
