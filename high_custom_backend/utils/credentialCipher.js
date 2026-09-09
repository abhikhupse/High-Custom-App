const crypto = require("node:crypto");

function encryptionKey() {
  const secret = String(
    process.env.GODADDY_CREDENTIAL_KEY || process.env.JWT_SECRET || "",
  );
  if (secret.length < 32) {
    throw new Error(
      "GODADDY_CREDENTIAL_KEY must be configured with at least 32 characters.",
    );
  }
  return crypto.createHash("sha256").update(secret, "utf8").digest();
}

function encryptCredential(value) {
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv("aes-256-gcm", encryptionKey(), iv);
  const ciphertext = Buffer.concat([
    cipher.update(String(value), "utf8"),
    cipher.final(),
  ]);
  return {
    passwordCiphertext: ciphertext.toString("base64"),
    passwordIv: iv.toString("base64"),
    passwordAuthTag: cipher.getAuthTag().toString("base64"),
  };
}

function decryptCredential({ passwordCiphertext, passwordIv, passwordAuthTag }) {
  const decipher = crypto.createDecipheriv(
    "aes-256-gcm",
    encryptionKey(),
    Buffer.from(passwordIv, "base64"),
  );
  decipher.setAuthTag(Buffer.from(passwordAuthTag, "base64"));
  return Buffer.concat([
    decipher.update(Buffer.from(passwordCiphertext, "base64")),
    decipher.final(),
  ]).toString("utf8");
}

module.exports = { encryptCredential, decryptCredential };
