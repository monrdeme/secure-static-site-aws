# Secure Static Website on AWS with Terraform and Python
This project demonstrates how to deploy and secure a static website hosted on Amazon S3 using Infrastructure as Code (Terraform) and Python scripting for automation. The goal is to follow AWS security best practices around permissions, monitoring, and alerting, while keeping it accessible and scalable.

---

## Architecture

![Architecture Diagram](./assets/architecture.png) <!-- Replace with actual path or hosted link -->

---

## Technologies Used

- **Terraform** – Infrastructure as Code to provision AWS resources
- **Python (Boto3)** – Automate file uploads and S3 permission checks
- **Amazon S3** – Host static website and store CloudTrail logs
- **AWS IAM** – Secure role-based access control with least-privilege permissions to resources
- **AWS CloudTrail** – Log and monitor API activity
- **Amazon GuardDuty** – Threat detection and continuous security monitoring
- **Amazon EventBridge** – Trigger actions based on CloudTrail and GuardDuty findings
- **Amazon CloudWatch** – Underlying log and event visibility
- **Amazon SNS** – Email notifications for security alerts
- **Amazon DynamoDB** – Store Terraform state locks for safe collaboration
- **GitHub Actions** – CI/CD pipeline for automatic deployments to AWS
- **Git/Github** – Version control and source code hosting

---

## Prerequisites

Before you begin, ensure you have the following:

- **AWS Account** with administrative access
- **Verified Email Address** in AWS (for SNS subscriptions)
- **Terraform installed** (v1.3+ recommended)
- **Python 3.8+** with `boto3` installed
- **Git installed**
- **GitHub Repository** set up and linked locally
- **AWS CLI configured** locally (`aws configure`)
- **IAM User/Role** with necessary permissions to provision AWS resources and upload to S3

---

## Table of Contents

1. [Deployment Workflow](#project-overview)
    - [Step 1: Create Static Website Files](#step-1-create-static-website-files)
    - [Step 2: Configure Terraform Remote State](#step-2-configure-terraform-remote)
    - [Step 3: Configure Terraform Variables](#step-3-configure-terraform-variables)
    - [Step 4: S3 Buckets Configuration](#step-4-s3-buckets-configuration)
    - [Step 5: IAM Roles and Policies](#step-iam-roles-and-policies)
    - [Step 6: Enable CloudTrail and Logging](#step-6-enable-cloudtrail-and-logging)
    - [Step 7: Enable GuardDuty](#step-7-enable-guardduty)
    - [Step 8: Configure Cloudwatch Log Group and EventBridge Ruless](#step-8-configure-cloudwatch-log-group-and-eventbridge-rules)
    - [Step 9: Configure SNS Notifications](#step-9-configure-sns-notifications)
    - [Step 10: Automate File Uploads](#step-10-automate-file-uploads)
    - [Step 11: Configure GitHub Actions CI/CD](#step-11-configure-github-actions-cicd)
6. [Screenshots](#screenshots)
7. [Security Best Practices Implemented](#security-best-practices-implemented)
8. [Conclusion](#conclusion)

---

## Deployment Workflow

### Step 1: Create Static Website Files (`index.html`, `error.html`)

**Purpose**:
-  Provide the content for the static website

[index.html](https://github.com/monrdeme/secure-static-site-aws/blob/main/website/index.html)  
[error.html](https://github.com/monrdeme/secure-static-site-aws/blob/main/website/error.html)  

---

### Step 2: Configure Terraform Remote State

**Purpose**: 
- Store Terraform state files remotely
- Enable state locking to prevent concurrent modifications

**Actions**:
#### 1. Create S3 Bucket for Terraform State
- Go to the **AWS Console > S3**
- Click **Create bucket**
- Name the bucket (e.g. `secure-static-site-aws-tf-state`)
- Block all public access
- Enable **Versioning** (important for rollback)
- Leave the rest as default, and create the bucket

#### 2. Create DynamoDB Table for State Locking
- Go to the **AWS Console > DynamoDB**
- Click **Create table**
- **Table name**: (e.g. `tf-state-lock`)
- **Partition key**: `LockID` (Type: String)
- Leave all other settings as default
- Create the table

#### 3. Update `backend.tf`
In your Terraform project, update or create `backend.tf`:

[backend.tf](https://github.com/monrdeme/secure-static-site-aws/blob/main/terraform/backend.tf)

#### 4. Initialize Terraform Backend
`terraform init`

---

### Step 3: Configure Terraform Variables (`variables.tf`)

**Purpose**:
- Centralize configuration values such as S3 bucket names, region, and resource names
- Enable reuse across multiple Terraform files
- Keep infrastructure code DRY (Don’t Repeat Yourself)

**Actions**:
#### 1. Create or open the `variables.tf` file in the `terraform/` directory
#### 2. Define your input variables
- AWS resource names
- AWS region
- Email address

[variables.tf](https://github.com/monrdeme/secure-static-site-aws/blob/main/terraform/variables.tf)

---

### Step 4: S3 Buckets Configuration (`s3.tf`)

**Purpose**:
- Host static website content and store logs.

**Security Measures**:
- Enabled versioning and server-side encryption on all buckets.
- Blocked public access, with exceptions for read-only access to HTML files in the website bucket.
- Applied strict bucket policies to prevent unauthorized access.

**Implementation Details**:  
- `secure-static-site-aws` bucket:
    - Static website hosting enabled.
    - Configured index and error documents.
  
- `secure-static-site-aws-logging` bucket:
    - Dedicated for CloudTrail logs.
    - Public access completely blocked.

**Screenshots to Include**:
- Public access settings
- Bucket policy viewer
- Static website hosting tab

[s3.tf](https://github.com/monrdeme/secure-static-site-aws/blob/main/terraform/s3.tf)

---

### Step 5: IAM Roles and Policies (`iam.tf`)

**Purpose**:
- Define roles and permissions for resource access.

**Security Measures**:
- Created roles with the principle of least privilege.
- Implemented trust policies for controlled role assumption.
- Scoped inline policies to specific actions and resources.

**Screenshots to Include**:
- IAM Roles page
- Trust relationships
- Attached policies

[iam.tf](https://github.com/monrdeme/secure-static-site-aws/blob/main/terraform/iam.tf)

---

### Step 6: Enable CloudTrail and Logging (`cloudtrail.tf`)

**Purpose**:
- Log all management events across the account
- Send logs to the S3 logging bucket

**Screenshots to Include**:
- CloudTrail config page
- Event selector (Management events only)
- S3 log bucket config

[→ View `cloudtrail.tf`](https://github.com/monrdeme/secure-static-site-aws/blob/main/terraform/cloudtrail.tf)

---

### Step 7: Enable GuardDuty (`guardduty.tf`)

**Purpose**:
- Detect threats like port scanning, compromised credentials, or unusual activity

**Screenshots to Include**:
- GuardDuty console
- Sample findings
- Detector configuration

[→ View `guardduty.tf`](https://github.com/monrdeme/secure-static-site-aws/blob/main/terraform/guardduty.tf)

---

### Step 8: Configure Cloudwatch Log Group and EventBridge Rules (`cloudwatch.tf`)

**Purpose**:
- Forward:
  - CloudTrail abnormal API activity
  - High/Critical GuardDuty findings

**Screenshots to Include**:
- Event pattern config
- Target SNS topic
- Matched event preview

[→ View `cloudwatch.tf`](https://github.com/monrdeme/secure-static-site-aws/blob/main/terraform/cloudwatch.tf)

---

### Step 9: Configure SNS Notifications (`sns.tf`)

**Purpose**:
- Send security alerts via email

**Setup**:
- Two SNS topics: one for CloudTrail, one for GuardDuty
- Your email subscribed for alerts

**Screenshots to Include**:
- SNS topics and subscriptions
- Example email received

[→ View `sns.tf`](https://github.com/monrdeme/secure-static-site-aws/blob/main/terraform/sns.tf)

---

### Step 10: Automate File Uploads (`upload_files.py`)

**Purpose**:
- Upload all static website files in `./website/` to S3 with correct metadata (like `Content-Type`)

**Command**:

`python3 scripts/upload_files.py`

---

### Step 11: Configure GitHub Actions CI/CD (`deploy.yml`)

**Purpose**:
- CloudTrail abnormal API activity
- High/Critical GuardDuty findings

**Screenshots to Include**:
- Event pattern config
- Target SNS topic
- Matched event preview

[→ View `cloudwatch.tf`](https://github.com/monrdeme/secure-static-site-aws/blob/main/terraform/cloudwatch.tf)










