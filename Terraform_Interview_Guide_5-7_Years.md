# Terraform Interview Guide (5--7 Years)

## 1. Why Terraform State File?

**Answer:** Terraform uses the state file to maintain a mapping between
the Terraform configuration and the actual infrastructure. It stores
resource IDs and metadata so Terraform can determine what to create,
update, or delete during `plan` and `apply`.

### Follow-ups

-   **What does it store?**
    -   Resource IDs
    -   ARNs
    -   IP addresses
    -   Current attributes
-   **Does it contain sensitive data?**
    -   Yes. It may contain passwords, connection strings and secrets
        depending on resources. `sensitive = true` only hides CLI
        output; it does not encrypt the state.

------------------------------------------------------------------------

## 2. Remote Backend (S3 + DynamoDB)

**Why remote backend?** - Team collaboration - Centralized state -
Backup/versioning - Secure storage

**Why DynamoDB?** - State locking. - Prevents concurrent
`terraform apply`.

**If Jenkins crashes?** - Lock may remain. - Verify no active Terraform
process. - Run:

``` bash
terraform force-unlock <LOCK_ID>
```

------------------------------------------------------------------------

## 3. State Drift

**Definition** Infrastructure changes outside Terraform.

**Detection**

``` bash
terraform plan
```

**Fix** - If manual change is wrong → `terraform apply` - If manual
change is intended → update Terraform code.

------------------------------------------------------------------------

## 4. Data Sources

**Definition** Read existing resources without managing them.

**Use Cases** - Existing VPC - Existing Subnet - Existing Security
Group - Existing IAM Role

Example:

``` hcl
data "aws_subnet" "private" {
  filter {
    name="tag:Name"
    values=["private-subnet"]
  }
}

resource "aws_instance" "web" {
  subnet_id = data.aws_subnet.private.id
}
```

**Data Source vs Import**

  Data Source              Import
  ------------------------ ------------------------------
  Read existing resource   Terraform starts managing it
  No ownership             Ownership transferred

------------------------------------------------------------------------

## 5. count vs for_each

**count** - Identical resources - Index based

**for_each** - Different names/configuration - Key based

------------------------------------------------------------------------

## 6. Modules

**Why?** - Reusability - Standardization - Easier maintenance

Typical structure:

``` text
modules/
  vpc/
  ec2/
  alb/

environments/
  dev/
  qa/
  prod/
```

Modules communicate using **outputs** and **input variables**.

------------------------------------------------------------------------

## 7. Lifecycle

### create_before_destroy

Create replacement before deleting old resource.

### prevent_destroy

Protect critical resources like RDS.

### ignore_changes

Ignore externally managed attributes like tags.

### depends_on

Explicit dependency when Terraform cannot infer it.

------------------------------------------------------------------------

## 8. Provisioners

### local-exec

Runs on Terraform machine.

### remote-exec

Runs on remote EC2.

### null_resource

Used to execute scripts without creating infrastructure.

### local_file

Generate local files (e.g. Ansible inventory).

------------------------------------------------------------------------

## 9. Import

``` bash
terraform import aws_vpc.main vpc-12345
```

-   Imports resource into state.
-   Does NOT generate Terraform code.

------------------------------------------------------------------------

## 10. State Commands

``` bash
terraform state list
terraform state show aws_instance.web
terraform state rm aws_instance.web
terraform state mv old new
```

------------------------------------------------------------------------

## 11. Backend Questions

-   Local vs Remote backend
-   Why S3?
-   Why versioning?
-   Why backend can't use variables?
-   Backend migration:

``` bash
terraform init
```

------------------------------------------------------------------------

## 12. Production Scenarios

### Manual Security Group change

State drift → plan detects → apply restores.

### EC2 deleted manually

Terraform recreates it.

### State file deleted

Restore from S3 versioning. Otherwise recover using `terraform import`.

### Two engineers run apply

DynamoDB lock prevents corruption.

### Apply fails midway

Fix issue and rerun `terraform apply`.

### Existing VPC created by networking team

Use **data source**.

### Existing VPC now managed by your team

Use **terraform import**.

------------------------------------------------------------------------

# Interview Cheat Sheet

-   State = mapping between code and infrastructure.
-   Drift = manual changes outside Terraform.
-   Data Source = read existing resource.
-   Import = manage existing resource.
-   Modules = reusable code.
-   S3 = remote state.
-   DynamoDB = locking.
-   create_before_destroy = minimize downtime.
-   prevent_destroy = protect resources.
-   ignore_changes = ignore external updates.
-   depends_on = explicit dependency.
