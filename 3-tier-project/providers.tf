provider "aws" {
  region = var.aws_region

  # default_tags applied to every resource — no need to repeat in each module
  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Workspace   = terraform.workspace
      Project     = var.project_name
    }
  }
}
