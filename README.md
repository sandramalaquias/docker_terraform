
# Data Engineering - Docker & Terraform

The goal of this project is to build knowledge around Docker images, AWS, Terraform, Python packages (using `matplotlib` for data visualization), and sending graphs to Slack.

## AWS Tools

-   **AWS CLI**: For managing credentials
-   **CodeBuild**: To create and maintain the Docker image
-   **ECR**: To store and manage the image
-   **Lambda**: To run the Docker image from ECR
-   **IAM**: To handle authorizations
-   **CloudWatch**: For logging
-   **S3**: To store code and data

## Terraform Directory

The project is divided into distinct files:

-   **docker.tf**: Resources to zip the code
-   **iam.tf**: Manages secure access for workloads and workforces
-   **main.tf**: Main resources for the setup
-   **output.tf**: Variables that output process results
-   **providers.tf**: Specifies providers used in the project
-   **variables.tf**: Defines variables used in the process, some marked as sensitive
-   **terraform.tfvars**: Contains sensitive values such as Slack token and channel (excluded from Git for security reasons)
    
    > **Pro Tip:** `terraform.tvars` is excluded from version control. The content format is:    
    slack_token = "<your_slack_token>"    
    slack_channel = "<your_slack_channel>"    
> 
** note:
> the terraform state is store in this directory  
> the graph.png is the project terraform plan

![graph](https://github.com/user-attachments/assets/4a92f547-832d-4586-99a8-adfe8c1b5f61)


## Data

Sourced from the Brazilian Institute of Geography and Statistics (IBGE), focusing on state and city information, and stored in S3 in Parquet format.

## Code directory

-   **buildspec.yml**: Contains CodeBuild configuration
-   **Dockerfile**: Docker configuration for building the image
-   **docker-compose.yml**: Configures Docker for local use (not part of Terraform)
-   **estados.py**: Main code for gathering and processing data
-   **requirements.txt**: Python dependencies, including `matplotlib`

The resulting graph is sending to Slack.
![Screenshot from 2024-10-31 15-32-25](https://github.com/user-attachments/assets/e689c0d1-764e-4ef9-91bc-353a45a2d115)

## Run

1.  Install Terraform following [HashiCorp's documentation](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).
2.  Install the AWS CLI (for credential management).
3.  Run `terraform init` in the Terraform project directory.
4.  Run `terraform apply` to deploy the infrastructure.
5.  After apply, some files for terraform traceback will be created automatically
5.  In the AWS Console, build and debug with CodeBuild.
6.  Test the Lambda function.

> **Pro Tip:** For more on Terraform commands, check the HashiCorp documentation linked above.


