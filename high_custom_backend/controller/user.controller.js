const USER_COLLECTION = require("../model/user.model");
const bcrypt = require("bcrypt");
const nodemailer = require("nodemailer");
const jwt = require("jsonwebtoken");
const { getClientIp } = require("../utils/clientIp");

exports.register = async (req, res) => {
  try {
    const { firstName, lastName, phone, email, employerCode, password } =
      req.body;

    const cleanFirstName = firstName.trim();
    const cleanLastName = lastName.trim();
    const cleanPhone = phone.replace(/\s+/g, "");
    const cleanEmail = email.toLowerCase().trim();
    const cleanEmployerCode = employerCode.trim();

    // Check duplicate email, phone or employer code
    const userExists = await USER_COLLECTION.findOne({
      $or: [
        { email: cleanEmail },
        { phone: cleanPhone },
        { employerCode: cleanEmployerCode },
      ],
    });

    if (userExists) {
      if (userExists.email === cleanEmail) {
        return res.status(400).json({
          success: false,
          message: "User already exists with this email",
        });
      }

      if (userExists.phone === cleanPhone) {
        return res.status(400).json({
          success: false,
          message: "User already exists with this phone number",
        });
      }

      if (userExists.employerCode === cleanEmployerCode) {
        return res.status(400).json({
          success: false,
          message: "Employer code is already used",
        });
      }
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Generate OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    const otpExpires = new Date(Date.now() + 10 * 60 * 1000);

    // Create user
    const user = await USER_COLLECTION.create({
      firstName: cleanFirstName,
      lastName: cleanLastName,
      employerCode: cleanEmployerCode,
      email: cleanEmail,
      phone: cleanPhone,
      password: hashedPassword,
      isEmailVerified: false,
      emailOtp: otp,
      emailOtpExpires: otpExpires,
    });

    // Gmail transporter
    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
    });

    const mailOptions = {
      from: `"High Custom Jewellers" <${process.env.EMAIL_USER}>`,
      to: cleanEmail,
      subject: "Your Email Verification OTP - High Custom Jewellers",

      html: `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Verify Your Email</title>
</head>

<body style="
  margin:0;
  padding:0;
  background-color:#080808;
  font-family:Arial, Helvetica, sans-serif;
  color:#ffffff;
">

  <table
    width="100%"
    cellpadding="0"
    cellspacing="0"
    border="0"
    style="background-color:#080808; padding:40px 15px;"
  >
    <tr>
      <td align="center">

        <!-- Main Container -->
        <table
          width="100%"
          cellpadding="0"
          cellspacing="0"
          border="0"
          style="
            max-width:600px;
            background-color:#101313;
            border:1px solid #9f7a32;
            border-radius:18px;
            overflow:hidden;
          "
        >

          <!-- Header -->
          <tr>
            <td
              align="center"
              style="
                padding:35px 25px 28px;
                background-color:#080909;
                border-bottom:1px solid #2c2415;
              "
            >

              <div style="
                font-size:12px;
                letter-spacing:4px;
                color:#c9a45c;
                font-weight:bold;
                margin-bottom:12px;
              ">
                EST. 2026
              </div>

              <div style="
                font-size:26px;
                line-height:32px;
                font-weight:bold;
                letter-spacing:3px;
                color:#d4af68;
              ">
                HIGH CUSTOM
              </div>

              <div style="
                font-size:14px;
                letter-spacing:5px;
                color:#ffffff;
                margin-top:4px;
              ">
                JEWELLERS
              </div>

              <div style="
                margin-top:18px;
                width:45px;
                height:1px;
                background-color:#c9a45c;
              "></div>

            </td>
          </tr>

          <!-- Content -->
          <tr>
            <td style="padding:40px 35px;">

              <h1 style="
                margin:0 0 12px;
                text-align:center;
                font-size:26px;
                line-height:34px;
                color:#ffffff;
                font-weight:600;
              ">
                Verify Your Email
              </h1>

              <p style="
                margin:0 0 28px;
                text-align:center;
                font-size:15px;
                line-height:25px;
                color:#b9b9b9;
              ">
                Hello ${cleanFirstName},<br>
                Welcome to High Custom Jewellers.
              </p>

              <p style="
                margin:0 0 25px;
                text-align:center;
                font-size:15px;
                line-height:24px;
                color:#d6d6d6;
              ">
                Please use the verification code below
                to confirm your email address.
              </p>

              <!-- OTP Card -->
              <table
                width="100%"
                cellpadding="0"
                cellspacing="0"
                border="0"
              >
                <tr>
                  <td align="center">

                    <div style="
                      display:inline-block;
                      padding:20px 35px;
                      background-color:#181818;
                      border:1px solid #c9a45c;
                      border-radius:12px;
                      box-shadow:0 0 20px rgba(201,164,92,0.12);
                    ">

                      <div style="
                        font-size:11px;
                        letter-spacing:3px;
                        color:#9f9f9f;
                        margin-bottom:10px;
                        text-transform:uppercase;
                      ">
                        Verification Code
                      </div>

                      <div style="
                        font-size:36px;
                        line-height:42px;
                        font-weight:bold;
                        letter-spacing:10px;
                        color:#d4af68;
                        padding-left:10px;
                      ">
                        ${otp}
                      </div>

                    </div>

                  </td>
                </tr>
              </table>

              <!-- Expiry -->
              <p style="
                margin:28px 0 0;
                text-align:center;
                font-size:13px;
                line-height:22px;
                color:#a8a8a8;
              ">
                This verification code is valid for
                <strong style="color:#d4af68;">10 minutes</strong>.
              </p>

              <!-- Security Notice -->
              <table
                width="100%"
                cellpadding="0"
                cellspacing="0"
                border="0"
                style="
                  margin-top:32px;
                  background-color:#151515;
                  border-left:3px solid #c9a45c;
                "
              >
                <tr>
                  <td style="padding:15px 18px;">

                    <p style="
                      margin:0;
                      font-size:13px;
                      line-height:21px;
                      color:#b8b8b8;
                    ">
                      <strong style="color:#ffffff;">
                        Security Notice
                      </strong>
                      <br>
                      Never share this OTP with anyone.
                      High Custom Jewellers will never ask
                      you for your verification code.
                    </p>

                  </td>
                </tr>
              </table>

              <p style="
                margin:30px 0 0;
                text-align:center;
                font-size:13px;
                line-height:21px;
                color:#858585;
              ">
                If you did not create an account with us,
                you can safely ignore this email.
              </p>

            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td
              align="center"
              style="
                padding:25px 20px;
                background-color:#080909;
                border-top:1px solid #2c2415;
              "
            >

              <div style="
                font-size:12px;
                color:#777777;
                line-height:20px;
              ">
                © ${new Date().getFullYear()}
                High Custom Jewellers
              </div>

              <div style="
                margin-top:6px;
                font-size:11px;
                color:#555555;
              ">
                Crafted with elegance. Designed for you.
              </div>

            </td>
          </tr>

        </table>

      </td>
    </tr>
  </table>

</body>
</html>
`,
    };

    await transporter.sendMail(mailOptions);

    const createdAtIST = user.createdAt.toLocaleString("en-IN", {
      timeZone: "Asia/Kolkata",
    });

    return res.status(201).json({
      success: true,
      message: "Account created successfully. OTP sent to your email.",
      userId: user._id,
      email: user.email,
      createdAt: createdAtIST,
    });
  } catch (error) {
    console.error("Register error:", error);

    return res.status(500).json({
      success: false,
      message: "Internal Server Error",
      error: error.message,
    });
  }
};

exports.verifyOtp = async (req, res) => {
  try {
    console.log("========== VERIFY OTP API CALLED ==========");
    console.log("BODY:", req.body);

    const { email, otp } = req.body;

    if (!email || !otp) {
      console.log("Missing email or OTP");

      return res.status(400).json({
        success: false,
        message: "Email and OTP are required",
      });
    }

    const cleanEmail = String(email).trim().toLowerCase();
    const cleanOtp = String(otp).trim();

    console.log("Email:", cleanEmail);
    console.log("OTP:", cleanOtp);

    const user = await USER_COLLECTION.findOne({
      email: cleanEmail,
    });

    console.log("USER FOUND:", user);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    console.log("Before update:");
    console.log("User ID:", user._id);
    console.log("Email:", user.email);
    console.log("Stored OTP:", user.emailOtp);
    console.log("Entered OTP:", cleanOtp);
    console.log("Verified:", user.isEmailVerified);
    console.log("OTP Expiry:", user.emailOtpExpires);

    if (user.emailOtp !== cleanOtp) {
      console.log("OTP DOES NOT MATCH");

      return res.status(400).json({
        success: false,
        message: "Invalid OTP",
      });
    }

    if (new Date() > new Date(user.emailOtpExpires)) {
      console.log("OTP EXPIRED");

      return res.status(400).json({
        success: false,
        message: "OTP has expired",
      });
    }

    console.log("OTP MATCHED");

    // IMPORTANT
    user.isEmailVerified = true;
    user.emailOtp = null;
    user.emailOtpExpires = null;

    console.log("Before save:");
    console.log(user.isEmailVerified);

    const savedUser = await user.save();

    console.log("AFTER SAVE:");
    console.log("Verified:", savedUser.isEmailVerified);
    console.log("User ID:", savedUser._id);

    // Read the user AGAIN directly from MongoDB
    const checkUser = await USER_COLLECTION.findById(user._id);

    console.log("AFTER DATABASE READ:");
    console.log("Verified:", checkUser.isEmailVerified);

    return res.status(200).json({
      success: true,
      message: "Email verified successfully",
      userId: checkUser._id,
      email: checkUser.email,
      isEmailVerified: checkUser.isEmailVerified,
    });
  } catch (error) {
    console.error("VERIFY OTP ERROR:", error);

    return res.status(500).json({
      success: false,
      message: "Internal Server Error",
      error: error.message,
    });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, employerCode, password } = req.body;
    const normalizedEmail =
      typeof email === "string" ? email.trim().toLowerCase() : "";
    const normalizedEmployerCode =
      typeof employerCode === "string" ? employerCode.trim() : "";

    if ((!normalizedEmail && !normalizedEmployerCode) || !password) {
      return res.status(400).json({
        message: "Email or Employer Code and Password are required",
      });
    }

    const query = [];
    if (normalizedEmail) {
      query.push({ email: normalizedEmail });
    }
    if (normalizedEmployerCode) {
      query.push({ employerCode: normalizedEmployerCode });
    }

    const user = await USER_COLLECTION.findOne({
      $or: query,
    });

    if (!user) {
      return res.status(404).json({
        message: "User not found",
      });
    }

    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: "Invalid email or password",
      });
    }
    const token = jwt.sign(
      {
        id: user._id,
        email: user.email,
        employerCode: user.employerCode,
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || "7d" },
    );

    // Update the user's login status and remember this login-device IP.
    user.isLogIn = true;

    const loginIp = getClientIp(req);
    const loginUserAgent = String(req.headers["user-agent"] || "").slice(
      0,
      500,
    );

    if (loginIp) {
      if (!Array.isArray(user.loginDeviceIps)) {
        user.loginDeviceIps = [];
      }

      const existingDevice = user.loginDeviceIps.find(
        (device) => device.ipAddress === loginIp,
      );

      if (existingDevice) {
        existingDevice.userAgent = loginUserAgent;
        existingDevice.lastSeenAt = new Date();
      } else {
        user.loginDeviceIps.push({
          ipAddress: loginIp,
          userAgent: loginUserAgent,
          lastSeenAt: new Date(),
        });

        // Keep only the ten most recent login networks/devices.
        if (user.loginDeviceIps.length > 10) {
          user.loginDeviceIps = user.loginDeviceIps
            .sort(
              (a, b) =>
                new Date(b.lastSeenAt).getTime() -
                new Date(a.lastSeenAt).getTime(),
            )
            .slice(0, 10);
        }
      }
    }

    await user.save();

    return res.status(200).json({
      success: true,
      message: "Login successful",
      token,
    });
  } catch (error) {
    return res.status(500).json({
      message: "Internal Server Error",
      error: error.message,
    });
  }
};

exports.getUserDetails = async (req, res) => {
  try {
    const userId = req.user.id;

    const user = await USER_COLLECTION.findById(userId).select(
      "-password -emailOtp -emailOtpExpires",
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    return res.status(200).json({
      success: true,
      message: "User details retrieved successfully",
      user: {
        id: user._id,
        firstName: user.firstName,
        lastName: user.lastName,
        employerCode: user.employerCode,
        email: user.email,
        phone: user.phone,
        isEmailVerified: user.isEmailVerified,
        isLogIn: user.isLogIn,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
      },
    });
  } catch (error) {
    console.error("Get User Details error", error);

    return res.status(500).json({
      success: false,
      message: "Internal Server Error",
      error: error.message,
    });
  }
};

exports.logout = async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "User Authenthication Required",
      });
    }

    // Find User

    const user = await USER_COLLECTION.findById(userId);

    if (!user) {
      return res.status(400).json({
        success: false,
        message: "User Not Exists",
      });
    }

    user.isLogIn = false;

    await user.save();

    return res.status(200).json({
      success: true,
      message: "Logout successful.",
    });
  } catch (error) {
    console.error("Logout Error:", error);

    return res.status(500).json({
      success: false,
      message: "Internal Server Error",
      error: error.message,
    });
  }
};

exports.editProfile = async (req, res) => {
  try {
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "User authentication required",
      });
    }

    const { firstName, lastName, email, phone } = req.body;

    // ============================================================
    // UPDATE DATA
    // ============================================================

    const updateData = {};

    if (firstName !== undefined) {
      updateData.firstName = firstName;
    }

    if (lastName !== undefined) {
      updateData.lastName = lastName;
    }

    if (email !== undefined) {
      updateData.email = email;
    }

    if (phone !== undefined) {
      updateData.phone = phone;
    }

    // ============================================================
    // PROFILE IMAGE
    // ============================================================

    if (req.file) {
      updateData.profileImage = `/uploads/profile/${req.file.filename}`;
    }

    // ============================================================
    // UPDATE USER
    // ============================================================

    const updateUser = await USER_COLLECTION.findByIdAndUpdate(
      userId,
      {
        $set: updateData,
      },
      {
        returnDocument: "after",
        runValidators: true,
      },
    );

    // USER NOT FOUND

    if (!updateUser) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    // RESPONSE

    return res.status(200).json({
      success: true,
      message: "Profile updated successfully",
      user: updateUser,
    });
  } catch (error) {
    console.error("=================================");
    console.error("EDIT PROFILE ERROR:");
    console.error(error);
    console.error("=================================");

    return res.status(500).json({
      success: false,
      message: "Internal Server Error",
      error: error.message,
    });
  }
};
