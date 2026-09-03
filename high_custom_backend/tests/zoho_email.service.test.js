const test = require("node:test");
const assert = require("node:assert/strict");
const axios = require("axios");

const {
  sendZohoSequenceEmail,
  _private: { refreshAccessToken, classifyZohoError },
} = require("../services/zoho_email.service");

test("five consecutive Zoho sends use one valid token and return unique IDs", async () => {
  const originalPost = axios.post;
  let sendCount = 0;
  axios.post = async (url, payload, options) => {
    assert.match(url, /\/api\/accounts\/account-1\/messages$/);
    assert.equal(options.headers.Authorization, "Zoho-oauthtoken valid-token");
    assert.equal(payload.toAddress, "safe-test@example.com");
    sendCount += 1;
    return {
      status: 200,
      data: { status: { code: 200 }, data: { messageId: `message-${sendCount}` } },
    };
  };

  const integration = {
    _id: "integration-1",
    userId: "user-1",
    accountId: "account-1",
    email: "sender@example.com",
    accessToken: "valid-token",
    refreshToken: "refresh-token",
    expiresAt: new Date(Date.now() + 10 * 60 * 1000),
    save: async () => {},
  };

  try {
    const results = [];
    for (let index = 0; index < 5; index += 1) {
      results.push(
        await sendZohoSequenceEmail({
          integration,
          sequence: { subject: "Test", content: "Consecutive send test" },
          lead: { email: "safe-test@example.com", firstName: "Test" },
          baseUrl: "https://example.com",
        }),
      );
    }
    assert.equal(sendCount, 5);
    assert.deepEqual(
      results.map((result) => result.messageId),
      [1, 2, 3, 4, 5].map((number) => `zoho:message-${number}`),
    );
  } finally {
    axios.post = originalPost;
  }
});

test("concurrent requests share a single Zoho token refresh", async () => {
  const originalPost = axios.post;
  let refreshCount = 0;
  axios.post = async (url) => {
    assert.match(url, /\/oauth\/v2\/token$/);
    refreshCount += 1;
    await new Promise((resolve) => setTimeout(resolve, 10));
    return { data: { access_token: "refreshed-token", expires_in: 3600 } };
  };

  const integration = {
    _id: "integration-2",
    userId: "user-2",
    accessToken: "expired-token",
    refreshToken: "refresh-token",
    expiresAt: new Date(Date.now() - 1000),
    save: async () => {},
  };

  try {
    const tokens = await Promise.all(
      Array.from({ length: 10 }, () => refreshAccessToken(integration)),
    );
    assert.equal(refreshCount, 1);
    assert.deepEqual(new Set(tokens), new Set(["refreshed-token"]));
  } finally {
    axios.post = originalPost;
  }
});

test("a Zoho 401 refreshes once and retries the send once", async () => {
  const originalPost = axios.post;
  let sendCount = 0;
  let refreshCount = 0;
  axios.post = async (url, payload, options) => {
    if (url.endsWith("/oauth/v2/token")) {
      refreshCount += 1;
      return { data: { access_token: "fresh-token", expires_in: 3600 } };
    }

    sendCount += 1;
    if (sendCount === 1) {
      const error = new Error("Unauthorized");
      error.response = { status: 401, data: { message: "Unauthorized" } };
      throw error;
    }
    assert.equal(options.headers.Authorization, "Zoho-oauthtoken fresh-token");
    return {
      status: 200,
      data: { status: { code: 200 }, data: { messageId: "after-refresh" } },
    };
  };

  const integration = {
    _id: "integration-3",
    userId: "user-3",
    accountId: "account-3",
    email: "sender@example.com",
    accessToken: "stale-token",
    refreshToken: "refresh-token",
    expiresAt: new Date(Date.now() + 10 * 60 * 1000),
    save: async () => {},
  };

  try {
    const result = await sendZohoSequenceEmail({
      integration,
      sequence: { subject: "Test", content: "401 retry test" },
      lead: { email: "safe-test@example.com" },
      baseUrl: "https://example.com",
    });
    assert.equal(result.messageId, "zoho:after-refresh");
    assert.equal(sendCount, 2);
    assert.equal(refreshCount, 1);
  } finally {
    axios.post = originalPost;
  }
});

test("only transient Zoho failures are retryable", () => {
  assert.deepEqual(classifyZohoError({ response: { status: 429 } }), {
    failureType: "temporary_failure",
    retryable: true,
  });
  assert.deepEqual(classifyZohoError({ response: { status: 503 } }), {
    failureType: "temporary_failure",
    retryable: true,
  });
  assert.deepEqual(classifyZohoError({ response: { status: 403 } }), {
    failureType: "permission_error",
    retryable: false,
  });
});
