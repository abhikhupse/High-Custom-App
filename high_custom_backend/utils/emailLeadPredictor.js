// ============================================================
// EMAIL LEAD PREDICTOR
// ============================================================
//
// Purpose:
// Predict First Name / Last Name / Company from an email.
//
// IMPORTANT:
// This function should ONLY be used when the lead does not
// already contain name/company information.
//
// Examples:
//
// john.doe@gmail.com
// => John Doe
//
// rajverma@gmail.com
// => Raj Verma
//
// sales@company.com
// => Company
//
// info@company.com
// => Company
//
// it02.highcustomjewellers@gmail.com
// => High Custom Jewellers
//
// ak47.myself@gmail.com
// => -
//
// ============================================================

const GENERIC_LOCAL_PARTS = new Set([
  "info",
  "information",
  "sales",
  "sale",
  "support",
  "contact",
  "admin",
  "administrator",
  "hello",
  "help",
  "office",
  "marketing",
  "enquiry",
  "inquiry",
  "accounts",
  "accounting",
  "billing",
  "finance",
  "hr",
  "jobs",
  "career",
  "careers",
  "recruitment",
  "team",
  "service",
  "services",
  "customerservice",
  "customer",
  "orders",
  "order",
  "booking",
  "bookings",
  "reception",
  "mail",
  "email",
  "webmaster",
  "noreply",
  "no-reply",
  "newsletter",
]);

const FREE_EMAIL_DOMAINS = new Set([
  "gmail.com",
  "googlemail.com",
  "yahoo.com",
  "yahoo.co.in",
  "hotmail.com",
  "outlook.com",
  "live.com",
  "icloud.com",
  "me.com",
  "aol.com",
  "proton.me",
  "protonmail.com",
]);

// ============================================================
// MAIN FUNCTION
// ============================================================

function predictLeadFromEmail(email) {
  const cleanEmail = String(email || "")
    .trim()
    .toLowerCase();

  if (!cleanEmail || !cleanEmail.includes("@")) {
    return {
      firstName: "-",
      lastName: "-",
      company: "-",
      confidence: 0,
      source: "invalid",
    };
  }

  const parts = cleanEmail.split("@");

  if (parts.length !== 2) {
    return {
      firstName: "-",
      lastName: "-",
      company: "-",
      confidence: 0,
      source: "invalid",
    };
  }

  const username = parts[0];
  const domain = parts[1];

  // ----------------------------------------------------------
  // COMPANY DOMAIN
  // ----------------------------------------------------------

  const domainWithoutTld = getCompanyNameFromDomain(domain);

  // ----------------------------------------------------------
  // GENERIC COMPANY EMAIL
  // ----------------------------------------------------------

  if (isGenericLocalPart(username)) {
    return {
      firstName: "-",
      lastName: "-",
      company: domainWithoutTld || "-",
      confidence: domainWithoutTld === "-" ? 0 : 0.9,
      source: "company-email",
    };
  }

  // ----------------------------------------------------------
  // PERSON NAME
  // ----------------------------------------------------------

  const namePrediction = predictPersonName(username);

  if (namePrediction) {
    return {
      firstName: namePrediction.firstName,
      lastName: namePrediction.lastName,
      company: "-",
      confidence: namePrediction.confidence,
      source: "person-email",
    };
  }

  // ----------------------------------------------------------
  // UNKNOWN
  // ----------------------------------------------------------

  return {
    firstName: "-",
    lastName: "-",
    company: "-",
    confidence: 0,
    source: "unknown",
  };
}

// ============================================================
// GENERIC EMAIL DETECTION
// ============================================================

function isGenericLocalPart(username) {
  const clean = username.replace(/[._-]/g, "").toLowerCase();

  return GENERIC_LOCAL_PARTS.has(username) || GENERIC_LOCAL_PARTS.has(clean);
}

// ============================================================
// PERSON NAME PREDICTION
// ============================================================

function predictPersonName(username) {
  let clean = username.toLowerCase().trim();

  // ----------------------------------------------------------
  // Remove obvious numeric-heavy usernames
  // ----------------------------------------------------------

  const digits = (clean.match(/\d/g) || []).length;

  if (digits > 0) {
    return null;
  }

  // ----------------------------------------------------------
  // Only allow reasonable name characters
  // ----------------------------------------------------------

  if (!/^[a-z]+([._-][a-z]+)+$/.test(clean)) {
    return null;
  }

  // ----------------------------------------------------------
  // Split separators
  // ----------------------------------------------------------

  const pieces = clean.split(/[._-]+/).filter(Boolean);

  // Need at least two parts
  if (pieces.length < 2) {
    return null;
  }

  // Too many pieces becomes unreliable
  if (pieces.length > 3) {
    return null;
  }

  // ----------------------------------------------------------
  // Reject very short / suspicious pieces
  // ----------------------------------------------------------

  if (pieces.some((part) => part.length < 2)) {
    return null;
  }

  // ----------------------------------------------------------
  // Check generic words
  // ----------------------------------------------------------

  if (pieces.some((part) => GENERIC_LOCAL_PARTS.has(part))) {
    return null;
  }

  // ----------------------------------------------------------
  // First two words
  // ----------------------------------------------------------

  const firstName = capitalizeWord(pieces[0]);

  const lastName = capitalizeWord(pieces[1]);

  // ----------------------------------------------------------
  // Confidence
  // ----------------------------------------------------------

  let confidence = 0.8;

  if (pieces.length === 2) {
    confidence = 0.9;
  }

  // Underscore / dot / hyphen names are strong signals
  if (/[._-]/.test(clean)) {
    confidence = Math.max(confidence, 0.9);
  }

  return {
    firstName,
    lastName,
    confidence,
  };
}

// ============================================================
// COMPANY NAME FROM DOMAIN
// ============================================================

function getCompanyNameFromDomain(domain) {
  if (!domain) {
    return "-";
  }

  const cleanDomain = domain.toLowerCase().trim();

  // ----------------------------------------------------------
  // Free email providers
  // ----------------------------------------------------------

  if (FREE_EMAIL_DOMAINS.has(cleanDomain)) {
    return "-";
  }

  // ----------------------------------------------------------
  // Split domain
  // ----------------------------------------------------------

  const domainParts = cleanDomain.split(".");

  if (domainParts.length < 2) {
    return "-";
  }

  // Remove TLD
  domainParts.pop();

  // Remove country code when applicable
  if (
    domainParts.length > 1 &&
    domainParts[domainParts.length - 1].length <= 3
  ) {
    domainParts.pop();
  }

  if (domainParts.length === 0) {
    return "-";
  }

  // Take actual company domain
  const companyPart = domainParts[domainParts.length - 1];

  if (!companyPart) {
    return "-";
  }

  // ----------------------------------------------------------
  // Convert company slug to readable text
  // ----------------------------------------------------------

  const readable = companyPart
    .replace(/[-_]+/g, " ")
    .replace(/([a-z])([A-Z])/g, "$1 $2")
    .replace(/\d+/g, "")
    .replace(/\s+/g, " ")
    .trim();

  if (!readable) {
    return "-";
  }

  return readable.split(" ").map(capitalizeWord).join(" ");
}

// ============================================================
// CAPITALIZE
// ============================================================

function capitalizeWord(value) {
  if (!value) {
    return "";
  }

  return value.charAt(0).toUpperCase() + value.slice(1).toLowerCase();
}

// ============================================================
// EXPORT
// ============================================================

module.exports = {
  predictLeadFromEmail,
};
