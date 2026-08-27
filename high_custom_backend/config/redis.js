const IORedis = require("ioredis");

function createRedisConnection() {
  const redisUrl = String(process.env.REDIS_URL || "").trim();

  if (!redisUrl) {
    throw new Error(
      "REDIS_URL is not configured. Example: redis://127.0.0.1:6379",
    );
  }

  const connection = new IORedis(redisUrl, {
    maxRetriesPerRequest: null,
    enableReadyCheck: true,
  });

  connection.on("error", (error) => {
    console.error("Redis connection error:", error.message);
  });

  return connection;
}

module.exports = {
  createRedisConnection,
};
