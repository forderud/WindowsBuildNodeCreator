Packer Getting started: [Build an image](https://developer.hashicorp.com/packer/tutorials/aws-get-started/aws-get-started-build-image) for AWS.


## Build instructions
Default build:
* ``packer build aws-ubuntu.pkr.hcl`

Command-line parameter:
* `packer build --var ami_prefix=learn-packer-aws-redis-var-flag aws-ubuntu.pkr.hcl`

Parameter file:
* `packer build --var-file=example.pkrvars.hcl aws-ubuntu.pkr.hcl`
