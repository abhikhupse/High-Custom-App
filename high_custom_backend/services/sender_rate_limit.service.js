const { createRedisConnection } = require("../config/redis");

const redis = createRedisConnection();

function positiveInteger(value, fallback) {
  const number = Number(value);
  return Number.isSafeInteger(number) && number > 0 ? number : fallback;
}
const EMAILS_PER_USER_WINDOW = positiveInteger(process.env.EMAILS_PER_USER_WINDOW, 1);
const EMAIL_USER_WINDOW_MS = positiveInteger(process.env.EMAIL_USER_WINDOW_MS, 60000);
const EMAILS_PER_USER_DAY = positiveInteger(process.env.EMAILS_PER_USER_DAY, 50);

// Check both windows before consuming either permit. Redis keeps this atomic
// across workers. The daily budget resets 24 hours after its first permit.
const RESERVE_SEND_SCRIPT = `
local waitMs = 0
local limits = {tonumber(ARGV[1]), tonumber(ARGV[2])}
local durations = {tonumber(ARGV[3]), 86400000}
for i = 1, 2 do
  local count = tonumber(redis.call("GET", KEYS[i]) or "0")
  if count >= limits[i] then
    waitMs = math.max(waitMs, redis.call("PTTL", KEYS[i]), 1)
  end
end
if waitMs > 0 then return {0, waitMs} end
for i = 1, 2 do
  local count = redis.call("INCR", KEYS[i])
  if count == 1 then redis.call("PEXPIRE", KEYS[i], durations[i]) end
end
return {1, 0}
`;

async function acquireUserSendPermit(userId) {
  if (!userId) {
    throw new Error("userId is required for the sender rate limit.");
  }

  const key = `highcustom:sender-rate:v2:${String(userId)}`;
  const result = await redis.eval(
    RESERVE_SEND_SCRIPT, 2, key, `${key}:day`,
    EMAILS_PER_USER_WINDOW, EMAILS_PER_USER_DAY, EMAIL_USER_WINDOW_MS,
  );

  return {
    allowed: Number(result[0]) === 1,
    waitMs: Math.max(0, Number(result[1]) || 0),
  };
}

module.exports = {
  acquireUserSendPermit,
  EMAILS_PER_USER_WINDOW,
  EMAILS_PER_USER_DAY,
  EMAIL_USER_WINDOW_MS,
};
