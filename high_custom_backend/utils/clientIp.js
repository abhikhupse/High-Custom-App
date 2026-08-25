function normalizeIp(value) {
  if (!value || typeof value !== "string") {
    return "";
  }

  let ip = value.split(",")[0].trim();

  if (ip.startsWith('"') && ip.endsWith('"')) {
    ip = ip.slice(1, -1);
  }

  if (ip.startsWith("::ffff:")) {
    ip = ip.substring(7);
  }

  return ip;
}

function getClientIp(req) {
  return normalizeIp(
    req.headers["cf-connecting-ip"] ||
      req.headers["x-forwarded-for"] ||
      req.ip ||
      req.socket?.remoteAddress ||
      "",
  );
}

module.exports = {
  getClientIp,
  normalizeIp,
};
