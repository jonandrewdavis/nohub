import { Container, getContainer, getRandom } from "@cloudflare/containers";
import { Hono } from "hono";

export class NohubContainer extends Container<Env> {
  // Port the container listens on (default: 8080)
  defaultPort = 9980;
  // Time before container sleeps due to inactivity (default: 30s)
  sleepAfter = "10m";
  // Environment variables passed to the container
  envVars = {
    NOHUB_GAMES: this.env.NOHUB_GAMES,
    NOHUB_TCP_HOST: this.env.NOHUB_TCP_HOST,
    NOHUB_METRICS_HOST: this.env.NOHUB_METRICS_HOST,
    NOHUB_METRICS_ENABLED: this.env.NOHUB_METRICS_ENABLED,
  };

  // Optional lifecycle hooks
  override onStart() {
    console.log("Container successfully started");
  }

  override onStop() {
    console.log("Container successfully shut down");
  }

  override onError(error: unknown) {
    console.log("Container error:", error);
  }
}

// Create Hono app with proper typing for Cloudflare Workers
const app = new Hono<{
  Bindings: Env;
}>();

// Home route with available endpoints
app.get("/", async (c) => {
  const containerId = c.env.NOHUB_CONTAINER.idFromName(`/container/1`);
  const container = c.env.NOHUB_CONTAINER.get(containerId);
  return await container.fetch(c.req.raw);
  // return c.text(
  //   "Available endpoints:\n" +
  //     "GET /container/<ID> - Start a container for each ID with a 2m timeout\n" +
  //     "GET /lb - Load balance requests over multiple containers\n" +
  //     "GET /error - Start a container that errors (demonstrates error handling)\n" +
  //     "GET /singleton - Get a single specific container instance"
  // );
});

// Route requests to a specific container using the container ID
app.get("/container/:id", async (c) => {
  const id = c.req.param("id");
  const containerId = c.env.NOHUB_CONTAINER.idFromName(`/container/${id}`);
  const container = c.env.NOHUB_CONTAINER.get(containerId);
  return await container.fetch(c.req.raw);
});

// Demonstrate error handling - this route forces a panic in the container
app.get("/error", async (c) => {
  const container = getContainer(c.env.NOHUB_CONTAINER, "error-test");
  return await container.fetch(c.req.raw);
});

// Load balance requests across multiple containers
app.get("/lb", async (c) => {
  const container = await getRandom(c.env.NOHUB_CONTAINER, 3);
  return await container.fetch(c.req.raw);
});

// Get a single container instance (singleton pattern)
app.get("/singleton", async (c) => {
  const container = getContainer(c.env.NOHUB_CONTAINER);
  return await container.fetch(c.req.raw);
});

export default app;
