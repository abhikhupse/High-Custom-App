const { createRedisConnection } = require("../config/redis");

const redis = createRedisConnection();

const EMAILS_PER_USER_WINDOW = Math.max(
  1,
  Number(process.env.EMAILS_PER_USER_WINDOW || 3),
);

const EMAIL_USER_WINDOW_MS = Math.max(
  1000,
  Number(process.env.EMAIL_USER_WINDOW_MS || 15000),
);

const RESERVE_SEND_SCRIPT = `
local key = KEYS[1]
local now = tonumber(ARGV[1])
local windowMs = tonumber(ARGV[2])
local maxPerWindow = tonumber(ARGV[3])

local windowStart = tonumber(redis.call("GET", key) or "0")

if windowStart <= 0 or windowStart + windowMs <= now then
  windowStart = now
  redis.call("SET", key, windowStart, "PX", windowMs)
  redis.call("SET", key .. ":count", 1, "PX", windowMs)
  return {1, 0}
end

local count = tonumber(redis.call("GET", key .. ":count") or "0")

if count < maxPerWindow then
  redis.call("INCR", key .. ":count")
  local ttl = redis.call("PTTL", key)
  if ttl > 0 then
    redis.call("PEXPIRE", key .. ":count", ttl)
  end
  return {1, 0}
end

local waitMs = (windowStart + windowMs) - now
if waitMs < 1 then
  waitMs = 1
end

return {0, waitMs}
`;

async function acquireUserSendPermit(userId) {
  if (!userId) {
    throw new Error("userId is required for the sender rate limit.");
  }

  const key = `highcustom:sender-rate:${String(userId)}`;
  const now = Date.now();

  const result = await redis.eval(
    RESERVE_SEND_SCRIPT,
    1,
    key,
    now,
    EMAIL_USER_WINDOW_MS,
    EMAILS_PER_USER_WINDOW,
  );

  return {
    allowed: Number(result[0]) === 1,
    waitMs: Math.max(0, Number(result[1]) || 0),
  };
}

module.exports = {
  acquireUserSendPermit,
  EMAILS_PER_USER_WINDOW,
  EMAIL_USER_WINDOW_MS,
};
