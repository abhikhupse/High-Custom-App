// ============================================================
// EMAIL LEAD PREDICTOR
// ============================================================
//
// Examples:
//
// abhikhupse@gmail.com
// -> Abhi / Khupse
//
// abhiikhupse@gmail.com
// -> Abhii / Khupse
//
// rajverma@gmail.com
// -> Raj / Verma
//
// rajeshverma@gmail.com
// -> Rajesh / Verma
//
// john.doe@gmail.com
// -> John / Doe
//
// john_doe@gmail.com
// -> John / Doe
//
// john-doe@gmail.com
// -> John / Doe
//
// sales@company.com
// -> - / - / Company
//
// info@company.com
// -> - / - / Company
//
// ak47.myself@gmail.com
// -> - / - / -
//
// ============================================================

const { COMMON_FIRST_NAMES } = require("./nameDictionary");

// ============================================================
// GENERIC EMAIL USERNAMES
// ============================================================

const GENERIC_EMAIL_NAMES = new Set([
  "sales",
  "info",
  "support",
  "admin",
  "contact",
  "hello",
  "office",
  "marketing",
  "hr",
  "careers",
  "career",
  "team",
  "enquiry",
  "inquiry",
  "billing",
  "accounts",
  "accounting",
  "finance",
  "jobs",
  "job",
  "service",
  "services",
  "help",
  "noreply",
  "no-reply",
  "notifications",
  "notification",
  "newsletter",
  "customerservice",
  "customer",
  "customers",
  "webmaster",
  "reception",
]);

// ============================================================
// NUMBER PATTERN
// ============================================================

const NUMBER_PATTERN = /\d/;

// ============================================================
// CLEAN WORD
// ============================================================

function cleanWord(word) {
  return String(word || "")
    .replace(/[^a-zA-Z]/g, "")
    .trim()
    .toLowerCase();
}

// ============================================================
// CAPITALIZE
// ============================================================

function capitalize(word) {
  if (!word) {
    return "";
  }

  return word.charAt(0).toUpperCase() + word.slice(1).toLowerCase();
}

// ============================================================
// FORMAT NAME
// ============================================================

function formatName(name) {
  return String(name || "")
    .split(/\s+/)
    .filter(Boolean)
    .map(capitalize)
    .join(" ");
}

// ============================================================
// PERSON USERNAME CHECK
// ============================================================

function looksLikePersonUsername(username) {
  if (!username) {
    return false;
  }

  // Any number means we treat the username as uncertain.
  if (NUMBER_PATTERN.test(username)) {
    return false;
  }

  const lettersOnly = username.replace(/[^a-zA-Z]/g, "");

  if (lettersOnly.length < 5) {
    return false;
  }

  return true;
}

// ============================================================
// SEPARATOR SPLIT
// ============================================================
//
// john.doe
// john_doe
// john-doe
//
// ============================================================

function splitBySeparator(username) {
  const parts = username
    .split(/[._-]+/)
    .map(cleanWord)
    .filter(Boolean);

  if (parts.length < 2) {
    return null;
  }

  const first = parts[0];

  const last = parts.slice(1).join(" ");

  if (!first || !last) {
    return null;
  }

  return {
    firstName: formatName(first),
    lastName: formatName(last),
    confidence: "high",
  };
}

// ============================================================
// FIND FIRST NAME PREFIX
// ============================================================
//
// IMPORTANT:
//
// We sort by longest name first.
//
// Example:
//
// rajeshverma
//
// Possible matches:
//
// raj
// rajesh
//
// "rajesh" wins because it is longer.
//
// ============================================================

function findFirstNamePrefix(username) {
  const normalized = username.toLowerCase();

  const matches = COMMON_FIRST_NAMES.filter((name) =>
    normalized.startsWith(name),
  ).sort((a, b) => {
    // Longest name first
    if (b.length !== a.length) {
      return b.length - a.length;
    }

    // Stable alphabetical fallback
    return a.localeCompare(b);
  });

  if (!matches.length) {
    return null;
  }

  for (const firstName of matches) {
    const remaining = normalized.slice(firstName.length);

    if (!remaining) {
      continue;
    }

    // Avoid extremely short surname fragments.
    if (remaining.length < 3) {
      continue;
    }

    return {
      firstName,
      lastName: remaining,
      confidence: "high",
    };
  }

  return null;
}

// ============================================================
// FIND BEST PERSON NAME
// ============================================================

function predictPersonName(username) {
  // ==========================================================
  // 1. Separator
  // ==========================================================

  const separated = splitBySeparator(username);

  if (separated) {
    return separated;
  }

  // ==========================================================
  // 2. Combined firstName + lastName
  // ==========================================================

  const prefixMatch = findFirstNamePrefix(username);

  if (prefixMatch) {
    return {
      firstName: formatName(prefixMatch.firstName),
      lastName: formatName(prefixMatch.lastName),
      confidence: prefixMatch.confidence,
    };
  }

  // ==========================================================
  // 3. Unknown
  // ==========================================================

  return {
    firstName: "-",
    lastName: "-",
    confidence: "low",
  };
}

// ============================================================
// COMPANY NAME FROM DOMAIN
// ============================================================
//
// Example:
//
// company.com
// -> Company
//
// highcustomjewellers.com
// -> High Custom Jewellers
//
// it02.highcustomjewellers.com
// -> High Custom Jewellers
//
// ============================================================

function predictCompanyFromDomain(domain) {
  if (!domain) {
    return "-";
  }

  const domainParts = domain.toLowerCase().split(".").filter(Boolean);

  if (!domainParts.length) {
    return "-";
  }

  let companyPart;

  // For subdomains:
  //
  // it02.highcustomjewellers.com
  //
  // choose highcustomjewellers
  if (domainParts.length >= 3) {
    companyPart = domainParts[domainParts.length - 2];
  } else {
    companyPart = domainParts[0];
  }

  companyPart = companyPart.replace(/[-_]+/g, " ").trim();

  if (!companyPart) {
    return "-";
  }

  // ==========================================================
  // Known company mappings
  // ==========================================================

  const companyMappings = {
    highcustomjewellers: "High Custom Jewellers",
    highcustomjewellers: "High Custom Jewellers",
    google: "Google",
    microsoft: "Microsoft",
    apple: "Apple",
    amazon: "Amazon",
    facebook: "Facebook",
    meta: "Meta",
    linkedin: "LinkedIn",
  };

  const normalized = companyPart.replace(/\s+/g, "").toLowerCase();

  if (companyMappings[normalized]) {
    return companyMappings[normalized];
  }

  return companyPart.split(/\s+/).filter(Boolean).map(capitalize).join(" ");
}

// ============================================================
// MAIN PREDICTOR
// ============================================================

function predictLeadFromEmail(email) {
  // ==========================================================
  // INVALID INPUT
  // ==========================================================

  if (!email || typeof email !== "string") {
    return {
      firstName: "-",
      lastName: "-",
      company: "-",
      confidence: "low",
    };
  }

  const normalizedEmail = email.trim().toLowerCase();

  const atIndex = normalizedEmail.indexOf("@");

  if (atIndex === -1) {
    return {
      firstName: "-",
      lastName: "-",
      company: "-",
      confidence: "low",
    };
  }

  const username = normalizedEmail.slice(0, atIndex).trim();

  const domain = normalizedEmail.slice(atIndex + 1).trim();

  if (!username || !domain) {
    return {
      firstName: "-",
      lastName: "-",
      company: "-",
      confidence: "low",
    };
  }

  // ==========================================================
  // GENERIC COMPANY EMAIL
  // ==========================================================

  if (GENERIC_EMAIL_NAMES.has(username)) {
    return {
      firstName: "-",
      lastName: "-",
      company: predictCompanyFromDomain(domain),
      confidence: "high",
    };
  }

  // ==========================================================
  // NUMBER-BASED USERNAME
  // ==========================================================
  //
  // ak47.myself@gmail.com
  //
  // We don't guess a person's identity.
  //
  // ==========================================================

  if (NUMBER_PATTERN.test(username)) {
    return {
      firstName: "-",
      lastName: "-",
      company: "-",
      confidence: "low",
    };
  }

  // ==========================================================
  // PERSON EMAIL
  // ==========================================================

  if (looksLikePersonUsername(username)) {
    const person = predictPersonName(username);

    return {
      firstName: person.firstName || "-",
      lastName: person.lastName || "-",
      company: "-",
      confidence: person.confidence || "low",
    };
  }

  // ==========================================================
  // UNKNOWN
  // ==========================================================

  return {
    firstName: "-",
    lastName: "-",
    company: "-",
    confidence: "low",
  };
}

// ============================================================
// EXPORT
// ============================================================

module.exports = {
  predictLeadFromEmail,
  predictCompanyFromDomain,
};
