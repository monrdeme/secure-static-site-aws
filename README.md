# Secure Static Website on AWS with Terraform and Python
This project demonstrates how to deploy and secure a static website hosted on Amazon S3 using Infrastructure as Code (Terraform) and Python scripting for automation. The goal is to follow AWS security best practices around permissions, monitoring, and alerting, while keeping it accessible and scalable.

---

## Architecture

![Architecture Diagram](./assets/architecture.png) <!-- Replace with actual path or hosted link -->

---

## Technologies Utilized

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
    - [Step 1: Create Static Website Files](#step-0-create-static-website-files)
    - [Step 2: Configure Terraform Remote State](#configure-terraform-remote-state)
    - [Step 3: Configure S3 Buckets](#step-1-configure-s3-buckets)
    - [Step 4: Configure IAM Roles](#step-2-configure-iam-roles)
    - [Step 5: Enable CloudTrail and Logging](#step-3-enable-cloudtrail-and-logging)
    - [Step 6: Enable GuardDuty](#step-4-enable-guardduty)
    - [Step 7: Create EventBridge Rules](#step-5-create-eventbridge-rules)
    - [Step 8: Configure SNS Notifications](#step-6-configure-sns-notifications)
    - [Step 9: Automate Upload with Python Script](#step-7-automate-upload-with-python-script)
    - [Step 10: Setup GitHub Actions CI/CD](#step-8-setup-github-actions-cicd)
6. [Screenshots](#screenshots)
7. [Security Best Practices Implemented](#security-best-practices-implemented)
8. [Conclusion](#conclusion)

---

## Deployment Workflow

### Step 1 (Setup): Manually Create S3 Bucket for Terraform State and DynamoDB Lock Table 

**Purpose**: 
- Store Terraform state files remotely
- Enable state locking to prevent concurrent modifications.

#### A. Create S3 Bucket for Terraform State
- Go to the **AWS Console > S3**
- Click **Create bucket**
- Name the bucket (e.g. `secure-static-site-tfstate`)
- Block all public access
- Enable **Versioning** (important for rollback)
- Leave the rest as default, and create the bucket

#### B. Create DynamoDB Table for State Locking
- Go to the **AWS Console > DynamoDB**
- Click **Create table**
- **Table name**: `terraform-locks`
- **Partition key**: `LockID` (Type: String)
- Leave all other settings as default
- Create the table

#### C. Update `backend.tf`
In your Terraform project, update or create `backend.tf`:

[→ View `backend.tf`](https://github.com/monrdeme/secure-static-site-aws/blob/main/terraform/backend.tf)

---

### Step 2: Configure S3 Buckets (`s3.tf`)

**Purpose**:
- One bucket for hosting the static site
- One logging bucket for CloudTrail

**Security Features**:
- Bucket versioning enabled
- Public ACLs blocked
- Website bucket policy allows *read-only* access to HTML files
- Logging bucket denies all public access

**Screenshots to Include**:
- Public access settings
- Bucket policy viewer
- Static website hosting tab

[→ View `s3.tf`](https://github.com/monrdeme/secure-static-site-aws/blob/main/terraform/s3.tf)

---

### Step 3: Create IAM Roles (`iam.tf`)

**Purpose**:
- Admin role: Full control
- Deployment role: Upload site content
- Website role: Read-only access to site

**Security Features**:
- Scoped actions (`s3:PutObject`, `s3:GetObject`, etc.)
- Defined assume-role trust policies

**Screenshots to Include**:
- IAM Roles page
- Trust relationships
- Attached policies

[→ View `iam.tf`](https://github.com/monrdeme/secure-static-site-aws/blob/main/terraform/iam.tf)

---

### Step 4: Enable CloudTrail (`cloudtrail.tf`)

**Purpose**:
- Log all management events across the account
- Send logs to the S3 logging bucket

**Screenshots to Include**:
- CloudTrail config page
- Event selector (Management events only)
- S3 log bucket config

[→ View `cloudtrail.tf`](https://github.com/monrdeme/secure-static-site-aws/blob/main/terraform/cloudtrail.tf)

---

### Step 5: Enable GuardDuty (`guardduty.tf`)

**Purpose**:
- Detect threats like port scanning, compromised credentials, or unusual activity

**Screenshots to Include**:
- GuardDuty console
- Sample findings
- Detector configuration

[→ View `guardduty.tf`](https://github.com/monrdeme/secure-static-site-aws/blob/main/terraform/guardduty.tf)

---

### Step 6: Configure EventBridge Rules (`cloudwatch.tf`)

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

### Step 7: Create Notification System with SNS (`sns.tf`)

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

### Step 8: Automate File Uploads (`upload_files.py`)

**Purpose**:
- Upload all static website files in `./website/` to S3 with correct metadata (like `Content-Type`)

**Command**:
```bash
python3 scripts/upload_files.py
