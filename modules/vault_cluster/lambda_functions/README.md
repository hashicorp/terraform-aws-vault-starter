# Build AWS Lambda Functions for use with this Terraform Module

This folder contains the two [Go](https://golang.org/) AWS Lambda functions that are required for this Terraform Module to operate. We package up the required zip files to deploy to AWS with Terraform, but provide the source and this Makefile if you wish to build the Lambda functions yourself.

You will need to have Go already installed.

For help:

```shell
$ make help
```

To build the Go binaries for Linux, and package into zip files, run:

```shell
$ make all
```
