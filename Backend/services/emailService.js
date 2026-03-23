const nodemailer = require('nodemailer');

// Create transporter for Gmail
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASSWORD,
  },
});

// Send verification email
const sendVerificationEmail = async (email, verificationCode) => {
  const mailOptions = {
    from: process.env.EMAIL_USER,
    to: email,
    subject: 'Verify Your Accessora Account',
    html: `
      <div style="font-family: Arial, sans-serif; padding: 20px; background-color: #f5f5f5;">
        <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; padding: 30px; border-radius: 8px; border: 2px solid #00D9FF;">
          <h2 style="color: #00D9FF; text-align: center;">Welcome to Accessora!</h2>
          <p style="color: #333;">Thank you for creating an account. Please use the code below to verify your email.</p>
          <div style="text-align: center; margin: 30px 0;">
            <p style="font-size: 32px; font-weight: bold; color: #00D9FF; letter-spacing: 5px; margin: 0;">${verificationCode}</p>
          </div>
          <p style="color: #666; text-align: center;">This code expires in 24 hours.</p>
          <p style="color: #999; font-size: 12px; margin-top: 30px;">If you didn't create this account, please ignore this email.</p>
        </div>
      </div>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    return true;
  } catch (error) {
    console.error('Error sending verification email:', error);
    return false;
  }
};

// Send password reset email
const sendPasswordResetEmail = async (email, resetCode) => {
  const mailOptions = {
    from: process.env.EMAIL_USER,
    to: email,
    subject: 'Reset Your Accessora Password',
    html: `
      <div style="font-family: Arial, sans-serif; padding: 20px; background-color: #f5f5f5;">
        <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; padding: 30px; border-radius: 8px; border: 2px solid #00D9FF;">
          <h2 style="color: #00D9FF; text-align: center;">Password Reset Request</h2>
          <p style="color: #333;">We received a request to reset your password. Please use the code below to create a new password.</p>
          <div style="text-align: center; margin: 30px 0;">
            <p style="font-size: 32px; font-weight: bold; color: #00D9FF; letter-spacing: 5px; margin: 0;">${resetCode}</p>
          </div>
          <p style="color: #666; text-align: center;">This code expires in 1 hour.</p>
          <p style="color: #999; font-size: 12px; margin-top: 30px;">If you didn't request this, please ignore this email.</p>
        </div>
      </div>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    return true;
  } catch (error) {
    console.error('Error sending password reset email:', error);
    return false;
  }
};

module.exports = {
  sendVerificationEmail,
  sendPasswordResetEmail,
};
