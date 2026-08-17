const {
  validateFirstName,
  validateLastName,
  validateEmployerCode,
  validateEmail,
  validatePhone,
  validatePassword,
} = require("../utils/validators");

const validateRegister = (req, res, next) => {
  const { firstName, lastName, employerCode, email, phone, password } =
    req.body;

  const errors = {};

  const firstNameError = validateFirstName(firstName);

  if (firstNameError) {
    errors.firstName = firstNameError;
  }

  const lastNameError = validateLastName(lastName);

  if (lastNameError) {
    errors.lastName = lastNameError;
  }

  const employerCodeError = validateEmployerCode(employerCode);

  if (employerCodeError) {
    errors.employerCode = employerCodeError;
  }

  const emailError = validateEmail(email);

  if (emailError) {
    errors.email = emailError;
  }

  const phoneError = validatePhone(phone);

  if (phoneError) {
    errors.phone = phoneError;
  }

  const passwordError = validatePassword(password);

  if (passwordError) {
    errors.password = passwordError;
  }

  if (Object.keys(errors).length > 0) {
    return res.status(400).json({
      success: false,
      message: "Validation failed",
      errors,
    });
  }

  next();
};

module.exports = {
  validateRegister,
};
