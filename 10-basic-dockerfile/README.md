# Basic Dockerfile

Project 10 of the [DevOps Roadmap](https://roadmap.sh/devops). Build a Docker image using Alpine Linux that prints a customizable greeting message.

## Project URL

https://roadmap.sh/projects/basic-dockerfile

---

## Architecture

```
Dockerfile
    │
    ▼
FROM alpine:latest          ← Minimal base image (~5MB)
    │
ARG NAME="Captain"          ← Build-time variable with default
    │
RUN echo "Hello, ${NAME}!" ← Executes at build time
    │
    ▼
Docker Image                ← Contains the printed message
    │
    ▼
docker run                  ← Outputs: Hello, Captain!
```

---

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) >= 20.0

### Verify Docker is installed

```bash
docker --version
# Docker version 24.x or higher
```

---

## Project Structure

```
10-basic-dockerfile/
├── Dockerfile       # Single instruction: print a greeting
└── README.md        # This file
```

---

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/wazaglo/devops-roadmap-projects.git
cd devops-roadmap-projects/10-basic-dockerfile
```

### 2. Build the Docker image

**Default build (Hello, Captain!):**

```bash
docker build -t hello .
```

**Custom name (Hello, Wisdom!):**

```bash
docker build --build-arg NAME=Wisdom -t hello .
```

### 3. Run the container

```bash
docker run hello
```

**Expected output (default):**

```text
Hello, Captain!
```

**Expected output (with custom name):**

```text
Hello, Wisdom!
```

---

## How It Works

### Dockerfile Breakdown

| Instruction | Purpose |
|-------------|---------|
| `FROM alpine:latest` | Uses Alpine Linux as the base image - small (~5MB), secure, minimal |
| `ARG NAME="Captain"` | Declares a build-time variable with a default value of "Captain" |
| `RUN echo "Hello, ${NAME}!"` | Executes the echo command during image build, printing the greeting |

### ARG vs ENV

| Feature | `ARG` | `ENV` |
|---------|-------|-------|
| Available at build time | Yes | Yes |
| Available at runtime | No | Yes |
| Passed via `--build-arg` | Yes | No |
| Set via `-e` flag | No | Yes |

This project uses `ARG` because the greeting only needs to be set during the build.

---

## Usage Examples

### Example 1: Default greeting

```bash
docker build -t hello .
docker run hello
# Output: Hello, Captain!
```

### Example 2: Custom name

```bash
docker build --build-arg NAME=Wisdom -t hello .
docker run hello
# Output: Hello, Wisdom!
```

### Example 3: Multiple builds with different names

```bash
# Build with default name
docker build -t hello-default .
docker run hello-default
# Output: Hello, Captain!

# Build with custom name
docker build --build-arg NAME=Alice -t hello-alice .
docker run hello-alice
# Output: Hello, Alice!

# Build with another name
docker build --build-arg NAME=Bob -t hello-bob .
docker run hello-bob
# Output: Hello, Bob!
```

### Example 4: Inspect the image

```bash
# List images
docker images | grep hello

# Inspect image history
docker history hello
```

---

## Docker Commands Reference

| Command | Purpose |
|---------|---------|
| `docker build -t hello .` | Build image from Dockerfile, tag it as "hello" |
| `docker run hello` | Run a container from the image |
| `docker images` | List all local images |
| `docker rmi hello` | Remove the image |
| `docker system prune` | Clean up unused containers/images |

---

## Cleanup

```bash
# Remove the image
docker rmi hello

# Remove all unused images
docker image prune -f
```

---

## Skills Demonstrated

| Skill | How |
|-------|-----|
| Docker | Dockerfile syntax, build process, image management |
| Alpine Linux | Minimal base image for container workloads |
| Build Arguments | Using ARG for parameterized builds |
| Containerization | Understanding how Docker images and containers work |

---

## What I Learned

- How to write a basic Dockerfile with FROM, ARG, and RUN instructions
- The difference between ARG (build-time) and ENV (runtime) variables
- How to pass build arguments using `--build-arg`
- How Alpine Linux serves as a lightweight base image
- The Docker build process: context → instructions → image layers

---

## Author

Wisdom Azaglo
