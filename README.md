# Società Storica Pinerolese — Website Infrastructure

Static website for the [Società Storica Pinerolese](https://societastoricapinerolese.it), a cultural association dedicated to the study and preservation of local history in the Pinerolo area (Piedmont, Italy).

The site is fully serverless and served globally via AWS CloudFront, with infrastructure managed as code using Terraform.

---

## About this project

This project was built as part of my transition from humanities academia to cloud engineering.

I hold a Bachelor's degree in History and a double Master's degree in Historical Sciences (University of Turin / Université Lyon 2). I am currently enrolled in the **AWS Cloud Architect** program at [ITS ICT Piemonte](https://www.ictpiemonte.it/).

The Società Storica Pinerolese is a real association I collaborate with. Building their digital infrastructure gave me a concrete, end-to-end project to apply cloud concepts beyond coursework — from static site hosting to DNS management, TLS certificates and CDN configuration, all defined as code.

---

## Architecture

```
User
 │
 ▼
Route 53 (DNS)
 │
 ▼
CloudFront (CDN + HTTPS termination)
 │
 ▼
S3 Bucket (origin — private, accessible only via OAC)
```

| Component | Service | Notes |
|---|---|---|
| DNS | AWS Route 53 | Hosted zone for `societastoricapinerolese.it` |
| CDN | AWS CloudFront | Global distribution, HTTPS redirect, custom domain |
| TLS Certificate | AWS ACM | DNS-validated, auto-renewed, provisioned in `us-east-1` |
| Storage | AWS S3 | Private bucket, no public access, served only via CloudFront OAC |
| IaC | Terraform | All infrastructure defined as code, no manual console changes |

**Security notes:**
- S3 bucket has all public access blocked
- CloudFront accesses S3 via **Origin Access Control (OAC)** — the modern replacement for the legacy OAI pattern
- HTTPS enforced via `redirect-to-https` viewer protocol policy
- TLS minimum version: `TLSv1.2_2021`

---

## Stack

- **Infrastructure:** Terraform, AWS (S3, CloudFront, Route 53, ACM)
- **Frontend:** HTML5, CSS3, vanilla JavaScript
- **Domain registrar:** OVH (nameservers delegated to Route 53)

---

## Repository structure

```
.
├── file_sito/          # Static website files
│   ├── index.html
│   ├── chi-siamo.html
│   ├── materiale.html
│   ├── collabora.html
│   ├── eventi.html
│   ├── error.html
│   └── style.css
├── main.tf             # Core infrastructure (S3, CloudFront, Route 53, ACM)
├── provider.tf         # AWS provider configuration
├── variable.tf         # Input variable declarations
├── local.tf            # Local values
├── output.tf           # Outputs (nameservers, CloudFront URL, site URL)
└── terraform.tfvars    # Variable values — not committed (see .gitignore)
```

---

## How to deploy

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) ≥ 1.0
- AWS CLI configured with appropriate credentials
- A registered domain (any registrar)

### Steps

```bash
# 1. Clone the repo
git clone https://github.com/societa-storica-pinerolese/societastoricapinerolese-website.git
cd societastoricapinerolese-website

# 2. Create your variable file
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your bucket name and domain

# 3. Initialise Terraform
terraform init

# 4. Review the plan
terraform plan

# 5. Apply
terraform apply
```

After apply, copy the 4 nameservers from the `nameservers` output into your domain registrar's DNS settings. ACM certificate validation and CloudFront propagation may take up to 15 minutes.

---

## Author

**Alessandro Verduna**
AWS Cloud Architect student @ ITS ICT Piemonte
[GitHub](https://github.com/AlessandroVerduna) · [Email](mailto:societastorica.pin@gmail.com)
