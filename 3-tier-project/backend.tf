# =============================================================================
# REMOTE BACKEND — S3 + DynamoDB state locking
#
# PREREQUISITE: Run global/backend-setup/ first to create these resources.
#
# Terraform workspaces automatically namespace state keys:
#   default   -> 3tier-app/terraform.tfstate
#   dev       -> env:/dev/3tier-app/terraform.tfstate
#   staging   -> env:/staging/3tier-app/terraform.tfstate
#   prod      -> env:/prod/3tier-app/terraform.tfstate
#
# This means each workspace has completely isolated state — safe for teams.
# DynamoDB ensures only one `terraform apply` runs at a time (state locking).
# =============================================================================

terraform {
  backend "s3" {
    bucket         = "YOUR-UNIQUE-BUCKET-NAME"   # Replace after running global/backend-setup
    key            = "3tier-app/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
