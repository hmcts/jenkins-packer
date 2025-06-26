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
