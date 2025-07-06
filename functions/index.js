const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const functions = require("firebase-functions"); // Required for config
const admin = require("firebase-admin");
const sgMail = require("@sendgrid/mail");
admin.initializeApp();

const SENDGRID_API_KEY =
  process.env.SENDGRID_API_KEY || functions.config().sendgrid.key;
const TEAM_EMAIL = 'quantiumbusiness@gmail.com';

sgMail.setApiKey(SENDGRID_API_KEY);

exports.sendContactEmails = onDocumentCreated("contact_submissions/{docId}", async (event) => {
  const data = event.data.data();

  // Team notification
  const teamMsg = {
    to: TEAM_EMAIL,
    from: TEAM_EMAIL, // Must be a verified sender in SendGrid!
    subject: `New Contact Us Enquiry from ${data.name}`,
    text: `Name: ${data.name}\nEmail: ${data.email}\n\nMessage:\n${data.message}`,
  };

  // Confirmation to user
  const userMsg = {
    to: data.email,
    from: TEAM_EMAIL,
    subject: 'We received your enquiry',
    text: `Hi ${data.name},\n\nThanks for reaching out! We've received your enquiry and will reply as soon as possible.\n\nBest regards,\nQuantium Business Team`,
  };

  // Send both emails
  await Promise.all([
    sgMail.send(teamMsg),
    sgMail.send(userMsg),
  ]);
  return null;
});
