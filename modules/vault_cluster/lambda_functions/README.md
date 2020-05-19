# Build AWS Lambda Functions for use with this Terraform Module

This folder contains the two [Golang](https://golang.org/) AWS Lambda functions that are required for this Terraform Module to operate. We package up the required zip files to deploy to AWS with Terraform, but provide the source and this Makefile if you wish to build the Lambda functions yourself.

You will need to have Golang already installed.

For help:

```shell
$ make help
```

To build the Golang binaries for Linux, and package into zip files, run:

```shell
$ make all
```
