# Hackathon App

A small Express service with a GitHub Actions DevSecOps pipeline.

## Setup

Requirements: Node.js 20 or newer, npm, Git, and Docker only if you want to build the image locally.

1. Clone the repository and create a feature branch.
2. Run `npm ci`.
3. Copy `.env.example` to `.env` and set local values. Never commit `.env` or credentials.
4. Install the pre-commit tool (`pip install pre-commit`) and run `pre-commit install` once.
5. Run `npm start`; open `http://localhost:3000` or `http://localhost:3000/health`.

## Workflow

Do not work directly on `main`. Open a pull request; the GitHub Actions workflows run secret scanning, tests, dependency auditing, SBOM generation, CodeQL, OWASP ZAP, and Trivy image scanning. Fix failed checks before merging. Enable branch protection on GitHub and require pull requests plus at least one review; CODEOWNERS requires replacing `@your-github-username` with the actual GitHub account.

## Container

Build with `docker build -t hackathon-app .` and run with `docker run --rm -p 3000:3000 hackathon-app`.
