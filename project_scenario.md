# Project Scenario: CI/CD Tools and Practices Final Project

## Overview

This project is the final assignment for the Coursera course **CI/CD Tools and Practices**. The goal is to build, test, and deploy a **Counter Service** — a RESTful API built with **Node.js** and **Express.js** — while implementing a complete CI/CD pipeline using industry-standard tools.

## Objective

Apply CI/CD best practices to a real-world microservice by:

1. Setting up a development environment
2. Writing and running automated tests
3. Building CI pipelines with **GitHub Actions**
4. Building CD pipelines with **Tekton**
5. Containerizing the application with **Docker**

## The Application: Counter Service

The Counter Service is a simple REST API that manages named counters stored in memory. Each counter has a name and an integer value.

### Tech Stack

| Component        | Technology              |
|------------------|-------------------------|
| Runtime          | Node.js (>=18)          |
| Framework        | Express.js 4.x          |
| Testing          | Jest + Supertest         |
| Linting          | ESLint                  |
| Security         | Helmet, CORS            |
| Logging          | Morgan + Custom Logger  |
| Containerization | Docker (node:18-alpine) |
| CI               | GitHub Actions          |
| CD               | Tekton                  |

### API Endpoints

| Method   | Endpoint           | Description              | Success Code |
|----------|--------------------|--------------------------|--------------|
| `GET`    | `/`                | Service information      | 200          |
| `GET`    | `/health`          | Health check             | 200          |
| `GET`    | `/counters`        | List all counters        | 200          |
| `POST`   | `/counters/:name`  | Create a new counter     | 201          |
| `GET`    | `/counters/:name`  | Read a specific counter  | 200          |
| `PUT`    | `/counters/:name`  | Increment a counter      | 200          |
| `DELETE` | `/counters/:name`  | Delete a counter         | 204          |

### Project Structure

```
ci-cd-final-project/
├── .github/workflows/    # GitHub Actions CI pipeline (to be created)
│   └── workflow.yml
├── .tekton/              # Tekton CD pipeline (to be created)
│   └── tasks.yml
├── bin/
│   └── setup.sh          # Environment setup script
├── src/
│   ├── app.js             # Express application entry point
│   ├── middleware/
│   │   ├── errorHandler.js  # Centralized error handling
│   │   └── logger.js        # Custom logging middleware
│   ├── routes/
│   │   └── counters.js      # Counter CRUD route handlers
│   └── utils/
│       └── status.js        # HTTP status code constants
├── tests/
│   └── counters.test.js   # Jest test suite
├── Dockerfile             # Container image definition
├── Procfile               # Process declaration (Heroku-style)
├── package.json           # Dependencies and scripts
└── README.md
```

## Tasks to Complete

### Task 1: Environment Setup

- Run `bin/setup.sh` to install dependencies
- Verify Node.js and npm are available
- Run `npm install` to install project dependencies

### Task 2: Run and Validate Tests

- Execute the test suite with `npm test`
- Ensure all 9 test cases pass (CRUD operations + health + service info)
- Generate coverage reports with `npm run test:coverage`

### Task 3: Lint the Code

- Run `npm run lint` to check code quality
- Fix any issues with `npm run lint:fix`

### Task 4: Create the CI Pipeline (GitHub Actions)

- Define a workflow in `.github/workflows/workflow.yml`
- The pipeline should:
  - Trigger on push/pull request
  - Install dependencies
  - Run linting
  - Run tests with coverage

### Task 5: Create the CD Pipeline (Tekton)

- Define Tekton tasks in `.tekton/tasks.yml`
- The pipeline should:
  - Build the Docker image
  - Deploy the containerized service

### Task 6: Containerize the Application

- Build the Docker image using the provided `Dockerfile`
- Run the container and verify the service responds on port 8000
- Test the health endpoint: `GET /health`

## Available Scripts

| Command               | Description                        |
|-----------------------|------------------------------------|
| `npm start`           | Start the service                  |
| `npm run dev`         | Start with auto-reload (nodemon)   |
| `npm test`            | Run the test suite                 |
| `npm run test:coverage` | Run tests with coverage report   |
| `npm run lint`        | Check code with ESLint             |
| `npm run lint:fix`    | Auto-fix linting issues            |

## Key Concepts Practiced

- **Continuous Integration**: Automated testing and linting on every push
- **Continuous Delivery**: Automated build and deployment pipeline
- **Containerization**: Packaging the app as a Docker image with a non-root user
- **Test-Driven Development**: Full test coverage for all API endpoints
- **Infrastructure as Code**: Pipeline definitions in YAML
- **Security Best Practices**: Helmet headers, CORS, non-root Docker user
