# Multi-Container Application

Project 11 of the [DevOps Roadmap](https://roadmap.sh/devops). A Node.js todo list API connected to MongoDB, running as two separate Docker containers orchestrated by Docker Compose.

## Project URL

https://roadmap.sh/projects/multi-container-service

---

## What This Project Does

You get a working **todo list API** that can:
- List all todos
- Create a new todo
- Read, update, or delete a specific todo

All todos are saved in a **MongoDB database**. Both the API and the database run inside their own Docker containers.

---

## Architecture

```
Your machine (port 3000)
       │
       ▼  curl http://localhost:3000
┌──────────────────────────────────┐
│         api container            │
│  Node.js + Express + Mongoose    │
│  Talks to MongoDB via hostname   │
│  "mongo" (not localhost)         │
└────────────┬─────────────────────┘
             │ mongodb://mongo:27017/todos
             ▼
┌──────────────────────────────────┐
│        mongo container           │
│  MongoDB 7                       │
│  Stores data in a named volume   │
└────────────┬─────────────────────┘
             ▼
┌──────────────────────────────────┐
│     mongo-data (Docker volume)   │
│  Survives container restarts     │
│  Wiped only with --volumes flag  │
└──────────────────────────────────┘
```

**Key insight:** Inside Docker Compose, containers talk to each other using the **service name** as the hostname. That's why the API connects to `mongodb://mongo:27017/todos` — `mongo` is the service name, not `localhost`.

---

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) >= 24.0

### Verify Docker is installed

```bash
docker --version
docker compose version
```

---

## Project Structure

```
11-multi-container-service/
│
├── api/                        # Node.js application source code
│   ├── models/
│   │   └── Todo.js             # Defines what a "todo" looks like in MongoDB
│   ├── routes/
│   │   └── todos.js            # All 5 API endpoint handlers
│   ├── server.js               # Entry point — starts Express + connects to MongoDB
│   └── package.json            # Lists dependencies (express, mongoose, dotenv, nodemon)
│
├── Dockerfile                  # Instructions to build the API's Docker image
├── docker-compose.yml          # Orchestrates both containers (api + mongo)
├── .env.example                # Template for environment variables
└── README.md                   # This file
```

---

## Getting Started

### 1. Start both containers

```bash
cd 11-multi-container-service
docker compose up -d
```

This command:
- Pulls the `mongo:7` image from Docker Hub (if not already cached)
- Builds the API image from the `Dockerfile`
- Creates a Docker network so the two containers can see each other
- Creates a named volume `mongo-data` for persistent storage
- Starts both containers in the background (`-d` = detached)

### 2. Verify everything is running

```bash
docker compose ps
docker compose logs api
```

You should see:
```
Connected to MongoDB
API running on port 3000
```

### 3. Test the API

Each curl command tests one endpoint:

```bash
# Check the API is alive
curl http://localhost:3000
# Response: Todo API is running

# Create a todo
curl -X POST http://localhost:3000/todos \
  -H "Content-Type: application/json" \
  -d '{"title":"Learn Docker Compose"}'

# List all todos
curl http://localhost:3000/todos

# Get a specific todo (replace <ID> with the _id from above)
curl http://localhost:3000/todos/<ID>

# Update a todo (mark it as completed)
curl -X PUT http://localhost:3000/todos/<ID> \
  -H "Content-Type: application/json" \
  -d '{"completed":true}'

# Delete a todo
curl -X DELETE http://localhost:3000/todos/<ID>
```

### 4. Stop the containers

```bash
# Stop without deleting data
docker compose down

# Stop AND delete all data (volume wiped)
docker compose down --volumes
```

### 5. Verify data persistence

```bash
# Create a todo
curl -X POST http://localhost:3000/todos \
  -H "Content-Type: application/json" \
  -d '{"title":"I will survive!"}'

# Stop everything (data stays in the volume)
docker compose down

# Start again
docker compose up -d

# Check — the todo is still there!
curl http://localhost:3000/todos
```

---

## How Each File Works

### `api/models/Todo.js` — The Database Schema

```javascript
const todoSchema = new mongoose.Schema({
  title: { type: String, required: true },   // Every todo MUST have a title
  completed: { type: Boolean, default: false }, // Default: not completed
}, { timestamps: true }); // Automatically adds createdAt and updatedAt
```

This is like creating a form template. It tells MongoDB: "Every todo document must have a `title` (text) and optionally a `completed` flag. Also, auto-track when it's created and updated."

### `api/routes/todos.js` — The 5 Endpoints

| Endpoint | What it does | Mongoose method used |
|----------|-------------|---------------------|
| `GET /todos` | Fetch all todos from MongoDB | `Todo.find()` |
| `POST /todos` | Create a new todo | `Todo.create()` |
| `GET /todos/:id` | Find one todo by its ID | `Todo.findById()` |
| `PUT /todos/:id` | Find and update fields | `Todo.findByIdAndUpdate()` |
| `DELETE /todos/:id` | Find and delete | `Todo.findByIdAndDelete()` |

Each handler is wrapped in `try/catch` — if anything goes wrong (bad ID, database down, etc.), it returns a 500 error with the message.

### `api/server.js` — The Entry Point

1. Loads environment variables from `.env` (or defaults)
2. Creates an Express app
3. Tells Express to expect JSON in request bodies (`app.use(express.json())`)
4. Connects to MongoDB using `mongoose.connect(MONGO_URI)`
5. Only starts the server **after** MongoDB confirms the connection

The `MONGO_URI` defaults to `mongodb://mongo:27017/todos` — notice the hostname is `mongo`, not `localhost`. That's how Docker Compose networking works: each service name becomes a hostname that other containers can reach.

### `Dockerfile` — Building the API Image

```dockerfile
FROM node:20-alpine          # Start with a lightweight Node.js base (~120MB)
WORKDIR /app                 # All commands run from /app inside the container
COPY api/package*.json ./    # Copy only package.json first (caching optimization)
RUN npm install              # Install dependencies
COPY api/ .                  # Copy the rest of the source code
EXPOSE 3000                  # Document that this image uses port 3000
CMD ["npm", "run", "dev"]    # Start with nodemon for hot-reload
```

**Why copy package.json separately?** Docker builds images in layers. If `package.json` hasn't changed, Docker reuses the cached `npm install` layer instead of re-installing everything. This makes rebuilds much faster.

### `docker-compose.yml` — The Conductor

```yaml
services:
  api:                        # First container
    build: .                  # Build from the Dockerfile in this directory
    ports:
      - "3000:3000"           # Map port 3000 on your machine → port 3000 in the container
    volumes:
      - ./api:/app            # Mount local code into container (hot-reload works!)
      - /app/node_modules     # Keep container's node_modules separate from your machine
    environment:
      - MONGO_URI=mongodb://mongo:27017/todos  # Connect to the "mongo" service
      - PORT=3000
    depends_on:
      - mongo                 # Wait for MongoDB to start first

  mongo:                      # Second container
    image: mongo:7            # Use the official MongoDB 7 image from Docker Hub
    volumes:
      - mongo-data:/data/db   # Persist database files in a named volume
    ports:
      - "27017:27017"         # Expose MongoDB port (optional — API connects internally)

volumes:
  mongo-data:                 # Declare the named volume
```

### The Volume Mount Trick

The line `volumes: - /app/node_modules` is important. When you mount `./api` (your local folder) over `/app` (the container's working directory), it would normally **hide** the `node_modules` folder that was installed during `docker build`. By adding `/app/node_modules` as a separate "anonymous volume," we tell Docker: "Use the container's own `node_modules`, not the host's." This way:
- Your local folder stays clean (no node_modules on your machine)
- The container has the correct Linux-native dependencies
- Hot-reload still works for all your source code

## What You Learn From This Project

| Concept | How it's demonstrated |
|---------|----------------------|
| Multi-container apps | API and database in separate containers |
| Docker Compose | Single config file to orchestrate multiple containers |
| Container networking | API connects to MongoDB using the service name `mongo` |
| Data persistence | Named volume `mongo-data` survives container restarts |
| Dockerfile best practices | Layer caching with `package.json` first |
| Volume mounts | Source code mount for hot-reload + node_modules isolation |
| Service dependencies | `depends_on` ensures MongoDB starts before the API |
| Environment variables | Config passed via Compose `environment` block |
| REST API design | 5 standard CRUD endpoints for a resource |



## Author

Wisdom Azaglo
