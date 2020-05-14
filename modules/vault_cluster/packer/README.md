# Build an AWS machine image with Packer

[Packer](https://www.packer.io/intro/index.html) is HashiCorp's open source tool
for creating identical machine images for multiple platforms from a single
source configuration.

The provided Packer template([packer.json](packer.json)) assumes there is a
`vars.json` file to go along with it (see [vars.json.example](vars.json.example)
for reference). Copy the contents of `vars.json.example` to a file named
`vars.json` and define the included variables appropriately.

Run the following command to validate your configuration:

```shell
$ packer validate -var-file=vars.json packer.json
```

You should see the following output:

```shell
$ packer validate -var-file=vars.json packer.json
Template validated successfully.
```

Run the following command to build your AMI:

```shell
$ packer build -var-file=vars.json packer.json
```

## Note:
Be sure to configure the specific
[ami_regions](https://www.packer.io/docs/builders/amazon-ebs.html#ami_regions)
in `packer.json` that you would like to deploy your AMI to. AMIs do not span
regions, so you will need to make sure a copy of your AMI exists in the region
you want to deploy your infrastructure.
