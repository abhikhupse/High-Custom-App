const SCANNER_USER_AGENT_PATTERNS = [
  /zohomail/i,
  /zoho[^\s/]*(?:scanner|security|proxy|preview)/i,
  /barracuda/i,
  /mimecast/i,
  /proofpoint/i,
  /messagelabs/i,
  /symantec.*(?:scanner|security)/i,
  /sophos/i,
  /fortimail/i,
  /trendmicro/i,
  /virus.*(?:scanner|check)/i,
  /spam.*(?:scanner|check)/i,
];

const AUTOMATION_USER_AGENT_PATTERN =
  /(?:^|[\s/(;])(?:bot|crawler|spider|headless|phantomjs|selenium|curl|wget)(?:$|[\s/);])/i;

function headerValue(headers, name) {
  const value = headers?.[name];
  return Array.isArray(value) ? value.join(",") : String(value || "");
}

function isRapidRequest(requestTime, delivery) {
  const sentAt = delivery?.sentAt || delivery?.createdAt || delivery?.scheduledAt;
  const sentTime = sentAt ? new Date(sentAt).getTime() : NaN;

  return (
    Number.isFinite(sentTime) &&
    requestTime.getTime() >= sentTime &&
    requestTime.getTime() - sentTime <= 15_000
  );
}

function detectEmailOpenScanner(req, delivery, requestTime = new Date()) {
  const headers = req?.headers || {};
  const userAgent = headerValue(headers, "user-agent").trim();
  const purpose = [
    headerValue(headers, "purpose"),
    headerValue(headers, "sec-purpose"),
    headerValue(headers, "x-purpose"),
    headerValue(headers, "x-moz"),
  ]
    .join(" ")
    .toLowerCase();

  // Gmail deliberately fetches remote images through GoogleImageProxy. Keep
  // accepting that request so the existing Gmail tracking behavior is not
  // changed by the Zoho/security-scanner filter.
  if (/googleimageproxy/i.test(userAgent)) {
    return { isScanner: false, reason: null };
  }

  if (SCANNER_USER_AGENT_PATTERNS.some((pattern) => pattern.test(userAgent))) {
    return { isScanner: true, reason: "known mail-security scanner user-agent" };
  }

  if (/(?:prefetch|preview|prerender|scanner|security)/i.test(purpose)) {
    return { isScanner: true, reason: "prefetch/security-scan request header" };
  }

  const rapidRequest = isRapidRequest(requestTime, delivery);

  if (rapidRequest && !userAgent) {
    return { isScanner: true, reason: "immediate request without a user-agent" };
  }

  if (rapidRequest && AUTOMATION_USER_AGENT_PATTERN.test(userAgent)) {
    return { isScanner: true, reason: "immediate automated request" };
  }

  return { isScanner: false, reason: null };
}

module.exports = {
  detectEmailOpenScanner,
};
