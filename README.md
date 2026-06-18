# jenkins-packer

## Description

This repo contains the scripts and config files to create Jenkins agent images.

## Requirements

- Packer

## Renovate config

Renovate has been configured to use the RegexManager with GitHub Tags and endoflife.date.

This will update the versions of tools and utilities in the provisioning script to the latest versions via pull request.

## Adding new packages to be updated by renovate

If you add a new package to the [provisioning script](./provision-jenkins-ubuntu-agent.sh) that can't be installed via package manager and should be updated regularly, add it to the block in the [provisioning script](https://github.com/hmcts/jenkins-packer/blob/master/provision-jenkins-ubuntu-agent.sh#L6-L25).

You will need to add a comment to inform renovate where to search for available versions e.g. on github with `#renovate: datasource=github-tags depName=fluxcd/flux2`

See [renovate datasources](https://docs.renovatebot.com/modules/datasource/) for a list of available sources.

By default, renovate will search for versions using `semver` but if your package uses another format, you will have to indicate what versioning to use e.g. `versioning=regex`

See [renovate versioning](https://docs.renovatebot.com/modules/versioning/) for a list of available versioning schemes.

Because a lot of github releases use `v` prefixes, we have an `echo` statement paired with the `tr` command to remove these in our script when setting the version to be used e.g. `export FLUX_VERSION=$(echo v0.41.2 | tr -d 'v')`.

## Testing a new image

When you raise a PR on this repo, it will generate an image using packer. By default the image is deleted after it has been built but if you need to test changes, you can add the `keep_image` label to your PR. This will prevent the image from being deleted during the pipeline and allows you to test the image without the need to merge changes to Master.

To actually run a Jenkins agent on your image and verify your changes, point a **sandbox (ptlsbox)** agent at it and trigger a build:

1. **Keep the image.** Add the `keep_image` label to your PR and let the pipeline finish. It publishes the image to the `hmcts` Azure Compute Gallery (image definition `jenkins-ubuntu-v2`) as version **`<PR-number>.0.0`** — e.g. PR #302 produces `302.0.0`. (Without the label the pipeline deletes the PR image at the end of the run.)

2. **Find your image version.** It's simply your PR number followed by `.0.0`. Confirm it exists in the gallery via the Azure Portal (Compute Gallery → `hmcts` → `jenkins-ubuntu-v2` → Versions) or the CLI:

   ```bash
   az sig image-version show \
     --gallery-name hmcts \
     --gallery-image-definition jenkins-ubuntu-v2 \
     --resource-group hmcts-image-gallery-rg \
     --gallery-image-version <PR-number>.0.0 \
     --subscription <image-gallery-subscription>
   ```

3. **Pin a sandbox agent to your image** by raising a PR on [`sds-flux-config`](https://github.com/hmcts/sds-flux-config) (see [PR #8566](https://github.com/hmcts/sds-flux-config/pull/8566) as a worked example):
   - In [`apps/jenkins/jenkins/ptlsbox/jenkins-azure-vm-agent.yaml`](https://github.com/hmcts/sds-flux-config/blob/master/apps/jenkins/jenkins/ptlsbox/jenkins-azure-vm-agent.yaml), set `galleryImageVersion` for the **`cnp-jenkins-builders`** template to your `<PR-number>.0.0`.
   - In `.github/renovate.json`, temporarily stop Renovate reverting it — add a `packageRule` disabling the agent-image dependency for that file (remove this during cleanup):

     ```json
     {
       "matchFileNames": ["apps/jenkins/jenkins/ptlsbox/jenkins-azure-vm-agent.yaml"],
       "matchPackageNames": ["hmcts/jenkins-packer"],
       "enabled": false
     }
     ```

4. **Merge the flux PR and confirm it applied.** Once Flux reconciles, log into the **ptlsbox cluster** and check the config has your version:

   ```bash
   kubectl -n jenkins get cm -o yaml | grep -E 'templateName|galleryImageVersion'
   ```

   You should see `<PR-number>.0.0` against `cnp-jenkins-builders`.

5. **Spin up a fresh agent.** Existing agents keep running the old image, so trigger a sandbox pipeline that uses the `cnp-jenkins-builders` agents — e.g. [`sds-toffee-recipes-service`](https://sds-sandbox-build.hmcts.net/job/HMCTS_Sandbox/job/sds-toffee-recipes-service/). A new agent provisions on your image and appears under **Build Executor Status** (bottom-left of <https://sds-sandbox-build.hmcts.net/>).

6. **Verify on the agent.** Click the new agent's name to open its **Script Console**, then run a check for your change. The console executes on the agent itself, e.g.:

   ```groovy
   println(["bash","-lc","which uv; uv --version"].execute().text)
   ```

7. **Clean up when done.** Revert the `sds-flux-config` changes (both the `galleryImageVersion` and the temporary Renovate `packageRule`), then merge your PR on this repo so the change ships in the next release image.

## SSH authentication

A SSH key is provided to packer to connect to and install on the image.

The SSH key is stored in and read from a keyvault.

To prevent issues with formatting of the key, it is stored in base64 format and must be decrypted by the script at runtime.

If you ever need to regenerate the SSH key being used, generate a new key and update the secret in the keyvault using azure-cli.

```
ssh-keygen -t ed25519 -C "jenkins@hmcts" -f <path-of-your-choosing>
export JENKINS_SSH_KEY=$(cat <path-of-your-choosing> | base64)
az keyvault secret set $JENKINS_SSH_KEY --vault-name <keyvault-name> --name jenkinsssh-private-key
az keyvault secret set -f <path-to-public-key> --vault-name <keyvault-name> --name jenkinsssh-public-key
```
You can find the keyvault details in `azure-pipelines.yml`

The SSH will not work just yet, you will need to add it to the service account.

Follow the instructions in [ops-runbooks](https://hmcts.github.io/ops-runbooks/azure-pipelines/github-sso.html#which-account-are-pats-created-under) to sign in as that account and add the key to the account under `Settings` > `SSH and GPG Keys` > `New SSH Key`.

Give the key a descriptive name like `Jenkins SSH Key`.

