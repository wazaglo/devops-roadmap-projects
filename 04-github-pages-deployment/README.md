# GitHub Pages Deployment Workflow

## Project Overview

This project demonstrates how to implement a simple Continuous Integration and Continuous Deployment (CI/CD) pipeline using GitHub Actions and GitHub Pages.

The repository contains a static website (`index.html`) and a GitHub Actions workflow that automatically deploys changes to GitHub Pages whenever the `index.html` file is modified and pushed to the `main` branch.

This project was completed as part of the DevOps Roadmap.

## Project URL

https://roadmap.sh/projects/github-pages

---

## Objectives

The goal of this project is to learn:

* GitHub Actions
* GitHub Pages
* Continuous Integration (CI)
* Continuous Deployment (CD)
* Workflow automation using YAML
* Event-driven deployments

---

## Project Structure

```text
devops-roadmap-projects/
│
├── 04-github-pages-deployment/
│   ├── index.html
│   └── README.md
│
└── .github/
    └── workflows/
        └── deploy-04.yml
```

### File Descriptions

| File          | Purpose                                            |
| ------------- | -------------------------------------------------- |
| index.html    | Static website content                             |
| README.md     | Project documentation                              |
| deploy-04.yml | GitHub Actions workflow (located at repository root) |

---

## How the CI/CD Pipeline Works

The deployment process is fully automated.

### Workflow Trigger

The GitHub Actions workflow is configured to run only when:

* A push is made to the `main` branch
* Any file in the `04-github-pages-deployment/` directory is modified

```yaml
on:
  push:
    branches:
      - main
    paths:
      - '04-github-pages-deployment/**'
```

This prevents unnecessary deployments when other files such as the README are updated.

---

## CI/CD Flow

```text
Developer
    │
    ▼
Modify index.html
    │
    ▼
git add .
git commit
git push
    │
    ▼
GitHub Actions Triggered
    │
    ▼
Checkout Repository
    │
    ▼
Configure GitHub Pages
    │
    ▼
Upload Website Files
    │
    ▼
Deploy to GitHub Pages
    │
    ▼
Website Updated Automatically
```

---

## GitHub Actions Workflow

The workflow file is located at:

```text
.github/workflows/deploy.yml
```

### Workflow Definition

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches:
      - main
    paths:
      - 'index.html'

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: true

jobs:
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}

    runs-on: ubuntu-latest

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Setup Pages
        uses: actions/configure-pages@v5

      - name: Upload Artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: .

      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

---

## Creating the Repository

Create a new repository on GitHub:

```text
gh-deployment-workflow
```

Clone the repository locally:

```bash
git clone https://github.com/<your-username>/gh-deployment-workflow.git

cd gh-deployment-workflow
```

---

## Creating the Website

Create an `index.html` file:

```html
<!DOCTYPE html>
<html>
<head>
    <title>GitHub Actions Demo</title>
</head>
<body>
    <h1>Hello, GitHub Actions!</h1>
</body>
</html>
```

---

## Enabling GitHub Pages

After pushing the repository, GitHub Pages must be enabled.

### Step 1

Open your repository on GitHub.

### Step 2

Navigate to:

```text
Settings
    └── Pages
```

### Step 3

Under **Build and Deployment**

Select:

```text
Source: GitHub Actions
```

### Step 4

Save the configuration.

GitHub will now allow deployments directly from GitHub Actions workflows.

---

## Deploying the Website

Commit and push the project:

```bash
git add .

git commit -m "feat: setup GitHub Pages deployment workflow"

git push origin main
```

---

## Monitoring Workflow Execution

Navigate to:

```text
Repository
    └── Actions
```

You should see:

```text
Deploy to GitHub Pages
```

A successful deployment will display a green checkmark.

---

## Accessing the Website

Once deployment completes successfully, the website becomes available at:

```text
https://<github-username>.github.io/<name-of-repo/
```

Example:

```text
https://wazaglo.github.io/devops-roadmap-projects/
```

---

## Testing the Pipeline

Update the website content:

```html
<h1>Hello, GitHub Actions!</h1>
```

Change it to:

```html
<h1>Hello, DevOps Roadmap!</h1>
```

Commit and push:

```bash
git add index.html

git commit -m "feat: update homepage"

git push
```

The workflow will automatically:

1. Detect the change
2. Execute the deployment workflow
3. Publish the updated website

No manual deployment steps are required.

---

## Verifying Path-Based Triggers

The workflow is configured to deploy only when `index.html` changes.

### Example 1

Updating the website:

```bash
git add index.html
git commit -m "update website"
git push
```

Result:

```text
Workflow Executes
Website Deploys
```

### Example 2

Updating documentation:

```bash
git add README.md
git commit -m "update documentation"
git push
```

Result:

```text
Workflow Does Not Execute
Website Is Not Redeployed
```

---

## Key Concepts Learned

### Continuous Integration (CI)

Automatically validates and processes code changes after every push.

### Continuous Deployment (CD)

Automatically publishes changes to production after successful workflow execution.

### GitHub Actions

GitHub's automation platform for building CI/CD pipelines.

### GitHub Pages

A static site hosting service provided by GitHub.

---

## Skills Demonstrated

* Git
* GitHub
* GitHub Actions
* GitHub Pages
* CI/CD Pipeline Design
* YAML Configuration
* Workflow Automation
* Static Website Deployment

---

## Author

Wisdom Azaglo

