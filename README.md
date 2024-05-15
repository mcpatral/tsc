# Introduction 
This project consists of deploying the infrastructure in Azure Cloud automatically using "Infrastructure as Code" with Terraform.

# Actual Terraform code

Terraform code is located under `terraform` folder in the root of this repository. This folder contains 3 root modules:

* Enablers
* Infrastructure
* Content

Also, it has `modules` folder that contains sub-modules with Generic resources declarations for root modules.

# Test Terraform code

If you want to check whether Terraform code is correct and it is working as expected, please follow steps below.

## Local validation

If you have Terraform binary installed on your laptop, you can do local validation. If you don't, just go to the next section. Local validation doesn't check how module works, but checks whether all variables and links are defined correctly. It allows to detect issues with code on early stage.

To do the validation, do these steps:

1. Open Terminal and go to module directory. Module directories are these:
  - terraform/enablers
  - terraform/infrastructure

2. Run these commands and check whether validation is successful
```
terraform init -backend=false
terraform validate
```

If it will print `Success` message, then you good to go and continue testing. If not, please fix these issues before proceeding with further steps. Please note that `validate` command also checks for deprecation and can display `warnings`. It is good practice to fix `warnings` as well.

## Pipelines

We have Azure DevOps YAML pipelines for Terraform modules deployment as well.
They are located [here](https://dev.azure.com/intrum-catalyst/igtpoc/_build?definitionScope=%5CDevOps%20Infra%5CTerraform).

To use them, you need to prepare your environment's `Variable Group` beforehand. To do it, you need to go to [Pipelines-Library](https://dev.azure.com/intrum-catalyst/igtpoc/_library?itemType=VariableGroups) and `Create Variable group`. 

You can clone existing one, but with unique name and replace environment specific values to ensure compatibility with other deployments. Please double check these values:

* `environment_type` <- Should be unique and has meaningful, not conflicting name
* `tf_backend_container_name` <- Should be unique per your environment

Once Variable Group created, you can run pipeline. Provide in input parameters your `Variable Group` name and select `Stages to Run` (in case if you want to run only one module, but not all of them).

# Pipelines code modification

In case if you need to modify pipeline code, the respective files are located in this repository as well. Symbol `<-` means that file on the left includes templates from the right.

```
Creation pipeline: 
deploy-terraform-pipeline.yml <- azure_pipelines/terraform-stages.yml <- azure_pipelines/templates/terraform-steps.yml

Destruction pipeline:
destroy-terraform-pipeline.yml <- azure_pipelines/terraform-stages.yml <- azure_pipelines/templates/terraform-steps.yml
```

If you added new variable to `Variable group` and/or `Terraform module`, you have to do the mapping of between those. To do it, please find block:
`planOptions: >-` in the `deploy-terraform-pipeline.yml` and `destroy-terraform-pipeline.yml` and add variable mapping there. Otherwise, `Terraform modules` won't be able to see variables you've provided in `Variable group`. 

Example:

```
...
planOptions: >-
  -var <terraform_module_var>=<variable_group_var_name>
  -var environment_type=$(environment_type)
...
```

Note that this approach will be changed in the future and this is temporary solution for passing variables.

# Pull request preparation

If you want to prepare PR into `main` branch, please include in description meaningful information about the changes and links to the successful pipelines runs.

# Feedback

If you have any questions or comments about information above, please feel free to contact Kirils Frolovs or Jurijs Ņemcevs