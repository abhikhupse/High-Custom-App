const admin = require("firebase-admin");
const DeviceToken = require("../model/device_token.model");

function firebaseApp() {
  if (admin.apps.length) return admin.app();
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw) return null;
  try {
    return admin.initializeApp({ credential: admin.credential.cert(JSON.parse(raw)) });
  } catch (error) {
    console.error("Firebase push configuration failed:", error.message);
    return null;
  }
}

function eventText(type) {
  return { opened: "read", replied: "replied to", interested: "is interested in", unsubscribed: "unsubscribed from" }[type] || "updated";
}

async function sendEmailEventPush({ userId, notificationId, email, type }) {
  const app = firebaseApp();
  if (!app) return;
  const devices = await DeviceToken.find({ userId }).lean();
  if (!devices.length) return;

  const result = await admin.messaging(app).sendEachForMulticast({
    tokens: devices.map((device) => device.token),
    notification: { title: "High Custom", body: `${email} has ${eventText(type)} your email.` },
    data: { route: "Notifications", notificationId: String(notificationId), type },
    android: { priority: "high" },
  });

  const invalid = devices
    .filter((_, index) => !result.responses[index]?.success)
    .filter((_, index) => ["messaging/registration-token-not-registered", "messaging/invalid-registration-token"].includes(result.responses[index]?.error?.code))
    .map((device) => device.token);
  if (invalid.length) await DeviceToken.deleteMany({ token: { $in: invalid } });
}

module.exports = { sendEmailEventPush };
