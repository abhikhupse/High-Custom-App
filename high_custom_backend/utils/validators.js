const validateFirstName = (value) => {
  const name = value?.trim() || "";

  if (!name) {
    return "First name is required";
  }

  if (name.length < 2) {
    return "First name must be at least 2 characters";
  }

  if (name.length > 50) {
    return "First name must not exceed 50 characters";
  }

  if (!/^[A-Z][a-zA-Z]*$/.test(name)) {
    return "First character must be uppercase and only letters are allowed";
  }

  return null;
};

const validateLastName = (value) => {
  const name = value?.trim() || "";

  if (!name) {
    return "Last name is required";
  }

  if (name.length < 2) {
    return "Last name must be at least 2 characters";
  }

  if (name.length > 50) {
    return "Last name must not exceed 50 characters";
  }

  if (!/^[A-Z][a-zA-Z]*$/.test(name)) {
    return "First character must be uppercase and only letters are allowed";
  }

  return null;
};

const validateEmployerCode = (value) => {
  const code = value?.trim() || "";

  if (!code) {
    return "Employer code is required";
  }

  if (!/^[a-zA-Z][a-zA-Z0-9]*$/.test(code)) {
    return "Must start with a letter and contain only letters and numbers";
  }

  return null;
};

const validateEmail = (value) => {
  const email = value?.trim() || "";

  if (!email) {
    return "Email address is required";
  }

  const emailRegex = /^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$/;

  if (!emailRegex.test(email)) {
    return "Enter a valid email address";
  }

  return null;
};

const validatePhone = (value) => {
  const phone = (value || "").replace(/\s+/g, "");

  if (!phone) {
    return "Phone number is required";
  }

  if (!/^[0-9]{10}$/.test(phone)) {
    return "Enter a valid 10 digit phone number";
  }

  return null;
};

const validatePassword = (value) => {
  if (!value) {
    return "Password is required";
  }

  if (!/^(?=.*[A-Z])(?=.*[a-z])(?=.*[!@#$%^&*]).{8,}$/.test(value)) {
    return "Min 8 chars, 1 uppercase, 1 lowercase & 1 special character";
  }

  return null;
};

module.exports = {
  validateFirstName,
  validateLastName,
  validateEmployerCode,
  validateEmail,
  validatePhone,
  validatePassword,
};
