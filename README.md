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
    - [Step 1: Static Website Files](#step-1-static-website-files)
    - [Step 2: Backend Configuration](#step-2-backend-configuration)
    - [Step 3: Terraform Variables](#step-3-terraform-variables)
    - [Step 4: S3 Buckets Configuration](#step-4-s3-buckets-configuration)
    - [Step 5: IAM Roles and Policies](#step-iam-roles-and-policies)
    - [Step 6: CloudTrail Configuration](#step-6-cloudtrail-configuration)
    - [Step 7: GuardDuty Configuration](#step-7-guardduty-configuration)
    - [Step 8: CloudWatch and EventBridge Configuration](#step-8-cloudwatch-and-eventbridge-configuration)
    - [Step 9: SNS Security Alerts](#step-9-sns-security-alerts)
    - [Step 10: Python Automation Script](#step-10-python-automation-script)
    - [Step 11: GitHub Actions Workflow](#step-11-configure-github-actions-cicd)
2. [Project Testing & Validation](#project-testing-&-validation)
   - [Test 1: Static Website Access](#test1-static-website-access)
   - [Test 2: IAM Role Assumption and Permissions](#test2-iam-role-assumption-and-permissions)
   - [Test 3: SNS Alerting](#test3-sns-alerting)
8. [Conclusion](#conclusion)

---

## Deployment Workflow

### Step 1: Static Website Files (`website/`)

**Purpose**:
- Provide the public-facing content for the static website hosted on S3.

**Security Measures**:
- Files do not contain dynamic scripts or sensitive information.
- HTML is validated to prevent injection or malformed rendering.
- Public read access is limited to these specific static files via bucket policy.

**Implementation Details**:
- `index.html`: Landing page of the site.
- `error.html`: Custom error page for 403/404 responses.

[website/](https://github.com/monrdeme/secure-static-site-aws/tree/main/website)
 
---

### Step 2: Backend Configuration (`backend.tf`)

**Purpose**: 
- Securely store Terraform state files for safe and collaborative infrastructure deployments.

**Security Measures**:
- S3 bucket with versioning and server-side encryption to protect Terraform state history.
- DynamoDB table for state locking to prevent concurrent operations.

**Implementation Details**:
- You must manually create:
    - An S3 bucket (e.g. `secure-static-site-aws-tf-state`)
        - Enable versioning
        - Enable encryption (SSE-S3 or SSE-KMS)
        - Block all public access
    - A DynamoDB Table (e.g. `tf-state-lock`)
        - With partition key: LockID (type: String)
- Once created, reference these in your backend.tf before running terraform init.

**Terraform State File Bucket**:
<img width="1212" alt="image" src="https://github.com/user-attachments/assets/977d3916-1ef8-4b31-bec6-0bd9a3bf7b1d">

**DynamoDB Table**:
<img width="1212" alt="image" src="https://i.imgur.com/EtP74v2.png">

[backend.tf](https://github.com/monrdeme/secure-static-site-aws/blob/main/terraform/backend.tf)

---

### Step 3: Terraform Variables (`variables.tf`)

**Purpose**:
- Centralize and manage configuration values across your Terraform modules.

**Security Measures**:
- Keeps secrets (e.g., email addresses) in a single location for easier management and review.
- Avoids hardcoding sensitive or environment-specific values directly in resource blocks.
- Simplifies reuse and promotes DRY (Don’t Repeat Yourself) principles.

**Implementation Details**:
- Defines key variables such as:
    - AWS region
    - S3 bucket names
    - IAM role names
    - Email address for SNS alerts

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

**Website and Logging Buckets**:
<img width="1212" alt="image" src="https://i.imgur.com/DuYdKYf.png">

[s3.tf](https://github.com/monrdeme/secure-static-site-aws/blob/main/terraform/s3.tf)

---

### Step 5: IAM Roles and Policies (`iam.tf`)

**Purpose**:
- Define roles and permissions for resource access.

**Security Measures**:
- Created roles with the principle of least privilege.
- Implemented trust policies for controlled role assumption.
- Scoped inline policies to specific actions and resources.

**Implementation Details**:
- **Admin Role**:
    - Full access to all project resources (used for provisioning and testing).
    - Trusted by your IAM user
- **Write-Only Role**:
    - Scoped permissions for uploading files to the website S3 bucket.
    - Allowed actions include `s3:PutObject` and `s3:ListBucket`.
    - Trusted by CI/CD pipeline (e.g., GitHub Actions).
- **Read-Only Role**:
    - Read-only access to the website content bucket.
    - Granted only `s3:GetObject` on specific paths.
    - Intended for static content consumers (e.g., public or CloudFront).

**IAM Roles**:
<img width="1212" alt="image" src="https://i.postimg.cc/jSM54WFF/image.png">

**IAM Policies**:
<img width="1212" alt="image" src="https://i.imgur.com/Cd529TA.png">

[iam.tf](https://github.com/monrdeme/secure-static-site-aws/blob/main/terraform/iam.tf)

---

### Step 6: Cloudtrail Configuration (`cloudtrail.tf`)

**Purpose**:
- Log all API activity across AWS services.

**Security Measures**:
- Configured CloudTrail to log all management events across regions.
- Directed logs to a secure, encrypted S3 bucket with public access blocked.
- Enforced bucket encryption and versioning.

**Implementation Details**:
- Single CloudTrail trail covering all regions.
- CloudTrail logs stored in the `secure-static-site-aws-logging` bucket.

**CloudTrail Trail**:
<img width="1212" alt="image" src="https://i.postimg.cc/SNxZR3cb/image.png">

[cloudtrail.tf](https://github.com/monrdeme/secure-static-site-aws/blob/main/terraform/cloudtrail.tf)

---

### Step 7: GuardDuty Configuration (`guardduty.tf`)

**Purpose**:
- Enable threat detection across AWS accounts.

**Security Measures**:
- Activated GuardDuty with all available detectors.
- Integrated with Cloudwatch and EventBridge to forward high-severity findings to SNS.
- Centralized alerting for suspicious behavior (e.g., anomalous API calls, port scanning).

**GuardDuty**:
<img width="1212" alt="image" src="https://i.postimg.cc/gJVwr95V/image.png">

[guardduty.tf](https://github.com/monrdeme/secure-static-site-aws/blob/main/terraform/guardduty.tf)

---

### Step 8: CloudWatch and EventBridge Configuration (`cloudwatch.tf`)

**Purpose**:
- Monitor security-related events and route them to appropriate destinations for alerting.

**Security Measures**:
- Created CloudWatch Log Groups to collect relevant logs.
- Configured EventBridge rules to match high-severity GuardDuty findings and sensitive CloudTrail activity.
- Integrated SNS as a target to ensure alerts are sent in real time.
- Ensured only necessary principals can create or modify EventBridge rules and targets.

**Implementation Details**:
- EventBridge rules match:
    - GuardDuty findings with severity ≥ 8.
    - CloudTrail events such as DeleteBucket, PutBucketPolicy, or AssumeRole.
- Rules forward matched events to SNS topics for email notifications.
- CloudWatch Log Group created for long-term centralized storage and future metric filtering.

**CloudWatch Logs Group for CloudTrail**:
<img width="1212" alt="image" src="https://i.postimg.cc/MKvZXMn6/image.png">

**EventBridge rules**:
<img width="1212" alt="image" src="https://i.postimg.cc/wvZmzW8J/image.png">

[cloudwatch.tf](https://github.com/monrdeme/secure-static-site-aws/blob/main/terraform/cloudwatch.tf)

---

### Step 9: SNS Security Alerts (`sns.tf`)

**Purpose**:
- Set up real-time security alerts to notify administrators of suspicious activity.

**Security Measures**:
- Created SNS topic for CloudTrail and GuardDuty alerts.
- Subscribed a verified email address to receive notifications.
- Restricted publish/subscribe permissions to authorized services and users.
- Integrated with EventBridge rules to trigger alerts for high-severity findings or events.

**Implementation Details**:
- SNS topic:
    - `secure-static-site-aws-security-alerts`
    - Email subscription requires manual confirmation.
    - Corresponds to the CloudTrail and GuardDuty EventBridge rules.
    - SNS topic policies limit publishing to EventBridge and restrict subscription management.

**SNS Topic**:
<img width="1212" alt="image" src="https://i.postimg.cc/c15XGHPy/image.png">

**SNS Subscription**:
<img width="1212" alt="image" src="https://i.postimg.cc/RFwd7QXc/image.png">

[sns.tf](https://github.com/monrdeme/secure-static-site-aws/blob/main/terraform/sns.tf)

---

### Step 10: Python Automation Script (`upload_files.py`)

**Purpose**:
- Automate the upload of static website content to the S3 bucket, ensuring correct metadata and permissions.

**Security Measures**:
- Checked S3 Bucket Permissions Before Uploading.
- Automatically set Content-Type headers for HTML, CSS, JS, and image files.
- Handled AWS SDK Errors Securely.

**Implementation Details**:
- Recursively scanned the local `website/` directory.
- Uploaded each file to the specified S3 bucket using `put_object()`.
- Set metadata (e.g., ContentType) based on file extension.
- Included logging for each file upload with success/failure status.

[upload_files.py](https://github.com/monrdeme/secure-static-site-aws/blob/main/scripts/upload_files.py)

---

### Step 11: GitHub Actions Workflow (`deploy.yml`)

**Purpose**:
- Automate website updates on code push.

**Security Measures**:
- Stored sensitive data in encrypted GitHub Secrets.
- Ran on GitHub-managed Ubuntu VM.
- Used the latest stable action versions.

**GitHub Actions Successfully Running Python Script to Deploy the Website with Permission Checks and Correct Content Types**:
<img width="1212" alt="image" src="https://i.postimg.cc/VkK4FWnt/image.png">

[deploy.yml](https://github.com/monrdeme/secure-static-site-aws/blob/main/.github/workflows/deploy.yml)

---

## Project Testing & Validation

### Test 1: Static Website Access
**Test Objective**: 
- Confirm that the static website is publicly accessible.

**Validation Steps**:
- Accessed the static website via the S3 website endpoint.

**Access to `index.html` Through the S3 Website Endpoint**.
<img width="1212" alt="image" src="https://i.postimg.cc/Xq8GfxmB/image.png">


<img width="1212" alt="image" src="https://i.postimg.cc/QCc81qYG/image.png">

---

### Test 2: IAM Role Assumption & Permissions
**Test Objective**: 
- Ensure that IAM roles can be assumed securely and that permissions are tightly scoped using least privilege.

**Validation Steps**:
- Successfully assumed each role using `sts:assume-role` (admin, write-only, read-only).
- Verified allowed actions (e.g., upload files with write-only, read objects with read-only).
- Attempted disallowed actions (e.g., read with write-only role) and confirmed access was denied.

**Admin Role Assumption**
<img width="1212" alt="image" src="https://i.postimg.cc/Kz03DwSS/image.png">

**Write-Only Role Assumption**
<img width="1212" alt="image" src="https://i.postimg.cc/rspnfBDS/image.png">

**Read-Only Role Assumption**
<img width="1212" alt="image" src="https://i.postimg.cc/zGMkNLVH/image.png">


---

### Test 3: SNS Security Alerts
**Test Objective**: 
- Validate that high-severity GuardDuty findings and specified CloudTrail events (e.g., high-risk IAM actions) trigger SNS notifications via EventBridge.

**Validation Steps**:
- GuardDuty Alerts:
    - Simulated GuardDuty findings using AWS sample findings.
    - Verified that EventBridge detected the finding and triggered the associated SNS topic.
    - Received the alert email successfully.
 
SNS Email Alert Received After a GuardDuty Finding was Detected.
<img width="1212" alt="image" src="https://i.imgur.com/NTCTURO.png)">

<img width="1212" alt="image" src="https://i.imgur.com/NTCTURO.png)">

- CloudTrail-Based Alerts:
    - Performed a monitored CloudTrail event (e.g., `DeleteBucket`, `PutBucketPolicy`, or `CreateUser`).
    - Confirmed that EventBridge matched the event pattern and invoked the SNS topic.
    - Received the notification email.

SNS alert triggered by a high-risk CloudTrail event such as `CreateUser`.
<img width="1212" alt="image" src="https://i.imgur.com/NTCTURO.png)">

<img width="1212" alt="image" src="https://i.imgur.com/NTCTURO.png)">

---

## Conclusion

This project demonstrates how to securely deploy a static website on AWS using Terraform and Python while following cloud security best practices. By combining infrastructure as code, role-based access control, automated deployments, and real-time monitoring, it provides a robust and scalable foundation suitable for production or learning environments.

Key takeaways include:

- Secure S3 configuration for public static content with minimal access exposure.
- IAM roles designed around least privilege and role assumption for better auditability.
- End-to-end monitoring and alerting through CloudTrail, GuardDuty, EventBridge, and SNS.
- Automation with Python and GitHub Actions to streamline operations and ensure consistent deployments.
