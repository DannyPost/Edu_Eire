const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe')(functions.config().stripe.secret);
const sgMail = require('@sendgrid/mail');

admin.initializeApp();
const db = admin.firestore();

const SENDGRID_API_KEY = functions.config().sendgrid.key;
const VERIFIED_SENDER = 'quantiumbusiness@gmail.com';
const TEAM_EMAIL = 'quantiumbusiness@gmail.com';
if (SENDGRID_API_KEY) sgMail.setApiKey(SENDGRID_API_KEY);

// 1. CREATE STRIPE CONNECT ACCOUNT & ONBOARDING LINK
exports.createStripeConnectAccount = functions.https.onCall(async (data, context) => {
  const { email, businessName } = data;
  if (!email) throw new functions.https.HttpsError('invalid-argument', 'Missing email');

  // Create Stripe Connect account
  const account = await stripe.accounts.create({
    type: 'express',
    email,
    business_type: 'company',
    business_profile: { name: businessName || 'Business User' },
    capabilities: { transfers: { requested: true } }
  });

  // Create onboarding link
  const accountLink = await stripe.accountLinks.create({
    account: account.id,
    refresh_url: 'https://your-app-url.com/reauth',     // Update with your URL
    return_url: 'https://your-app-url.com/onboarding-success', // Update with your URL
    type: 'account_onboarding',
  });

  return { stripeAccountId: account.id, onboardingUrl: accountLink.url };
});

// 2. CREATE STRIPE CHECKOUT SESSION WITH COMMISSION LOGIC (Connect)
exports.createStripeCheckoutSession = functions.https.onCall(async (data, context) => {
  const { items } = data; // [{id, qty}]
  if (!Array.isArray(items) || items.length === 0)
    throw new functions.https.HttpsError('invalid-argument', 'Cart empty');

  const productRefs = items.map(item => db.collection('products').doc(item.id));
  const productSnaps = await db.getAll(...productRefs);
  const products = productSnaps.map((snap, i) => {
    if (!snap.exists) throw new functions.https.HttpsError('not-found', `Product ${items[i].id} not found`);
    const data = snap.data();
    if (data.supply < items[i].qty) throw new functions.https.HttpsError('out-of-range', `Not enough stock for ${data.title}`);
    return { ...data, id: snap.id, qty: items[i].qty };
  });

  // Only allow checkout for 1 business per session!
  const businessEmails = new Set(products.map(p => p.adminId));
  if (businessEmails.size > 1) throw new functions.https.HttpsError('invalid-argument', 'All items must be from one business');
  const businessEmail = Array.from(businessEmails)[0];

  // Find business Stripe Account
  const adminSnap = await db.collection('admins').where('email', '==', businessEmail).limit(1).get();
  if (adminSnap.empty) throw new functions.https.HttpsError('not-found', 'Business admin not found');
  const business = adminSnap.docs[0].data();
  if (!business.stripeAccountId) throw new functions.https.HttpsError('failed-precondition', 'Business Stripe account not set up');

  // Build line_items and calculate commission (platform_fee)
  let total = 0;
  let commission = 0;
  const line_items = products.map(product => {
    const subtotal = product.price * product.qty;
    total += subtotal;
    // Commission logic
    let pct = 0.3;
    if (product.price > 1000) pct = 0.15;
    else if (product.price > 50) pct = 0.2;
    commission += subtotal * pct;
    return {
      price_data: {
        currency: 'eur',
        product_data: { name: product.title },
        unit_amount: Math.round(product.price * 100),
      },
      quantity: product.qty,
    };
  });

  // Stripe Connect destination charges (on_behalf_of business, fee to platform)
  const session = await stripe.checkout.sessions.create({
    payment_method_types: ['card'],
    line_items,
    mode: 'payment',
    success_url: 'https://your-app-url.com/success', // UPDATE!
    cancel_url: 'https://your-app-url.com/cancel',   // UPDATE!
    metadata: { items: JSON.stringify(items), businessEmail, stripeAccountId: business.stripeAccountId },
    payment_intent_data: {
      application_fee_amount: Math.round(commission * 100), // cents
      transfer_data: { destination: business.stripeAccountId },
    },
  });

  return { url: session.url };
});

// 3. STRIPE WEBHOOK: REDUCE INVENTORY
exports.handleStripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;
  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, functions.config().stripe.webhook);
  } catch (err) {
    console.error('❌ Stripe Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  if (event.type === 'checkout.session.completed') {
    const session = event.data.object;
    if (!session.metadata || !session.metadata.items) {
      console.error('❌ Stripe session missing items metadata');
      return res.status(400).send('Missing items metadata');
    }
    let items;
    try {
      items = JSON.parse(session.metadata.items);
      if (!Array.isArray(items)) throw new Error('items is not an array');
    } catch (err) {
      console.error('❌ Failed to parse items metadata:', err.message);
      return res.status(400).send('Invalid items metadata');
    }

    try {
      for (const item of items) {
        const ref = db.collection('products').doc(item.id);
        await db.runTransaction(async (t) => {
          const snap = await t.get(ref);
          if (!snap.exists) throw new Error(`Product not found: ${item.id}`);
          const data = snap.data();
          if (data.supply < item.qty) throw new Error(`Not enough stock for ${data.title}`);
          t.update(ref, { supply: data.supply - item.qty });
        });
        console.log(`✅ Updated stock for product ${item.id} by -${item.qty}`);
      }
      res.status(200).send('Inventory updated');
    } catch (err) {
      console.error('❌ Error updating inventory:', err.message);
      return res.status(500).send('Inventory update failed');
    }
  } else {
    res.status(200).send('Event ignored');
  }
});

// 4. BUSINESS SIGNUP: SEND EMAIL TO TEAM + BUSINESS
exports.notifyNewBusiness = functions.firestore
  .document('admins/{adminId}')
  .onCreate(async (snap, context) => {
    if (!SENDGRID_API_KEY) {
      console.warn("No SendGrid API key configured, skipping email.");
      return null;
    }
    const data = snap.data();
    // Email to your team
    const msgToTeam = {
      to: TEAM_EMAIL,
      from: VERIFIED_SENDER,
      subject: `New Business Registration: ${data.businessName || 'Unknown'}`,
      html: `
        <h2>New Business Registration Pending Approval</h2>
        <p><b>Business:</b> ${data.businessName}</p>
        <p><b>Email:</b> ${data.email}</p>
        <p><b>Sector:</b> ${data.sector}</p>
        <p><b>Size:</b> ${data.size}</p>
        <p><b>Stripe ID:</b> ${data.stripeAccountId}</p>
        <p>
          <a href="https://console.firebase.google.com/project/edueire-a3dc3/firestore/data/admins/${context.params.adminId}">
            Review in Firebase Console
          </a>
        </p>
      `,
    };
    // Email to business (optional)
    const msgToBusiness = {
      to: data.email,
      from: VERIFIED_SENDER,
      subject: 'Your business registration is under review!',
      html: `
        <h2>Thank you for registering your business</h2>
        <p>We have received your application for "${data.businessName || ''}".<br>
        Our team will review your submission and contact you soon!</p>
      `,
    };
    await sgMail.send(msgToTeam);
    await sgMail.send(msgToBusiness);
    return null;
  });
