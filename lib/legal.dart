// Plain-language policies; kept in sync with web/src/content/legal.ts.
library;

const legalUpdated = '17 October 2026';

typedef LegalSection = ({String title, List<String> body});

const List<LegalSection> privacyPolicy = [
  (title: 'What we collect', body: ['Order details you give us: name, mobile number, delivery address, optional email, the medicines you order and, if you upload one, your prescription.', 'Account details if you create an account: name, email, mobile number and a securely hashed password (we never store your password itself). If you sign in with Google we receive your name and email from Google.', 'Basic technical data needed to run the service, such as your browser or app version and the time of requests.']),
  (title: 'How we use it', body: ['To confirm, pack, deliver and support your orders, and to call you about them.', 'To show your order history, saved addresses and how much you saved.', 'To keep the service safe and working. We do not sell your data and we do not use your prescriptions or orders for advertising.']),
  (title: 'Who can see it', body: ['Our pharmacists and staff, only as needed to handle your order.', 'The delivery person sees your name, phone number, address and the amount to collect.', 'We share data with authorities only when the law requires it.']),
  (title: 'Prescriptions and health information', body: ['Prescriptions are visible only to our admin staff and are used only to check that the medicines you ordered match them.', 'Medicine information in Sashroy is for reference and price comparison. It is not medical advice.']),
  (title: 'How long we keep it', body: ['Order records are kept as long as the law requires a pharmacy to keep sales records.', 'You can delete your account at any time in the app (Settings → Account → Delete account). Your saved addresses and sign-in data are deleted; past orders remain as anonymous sales records.']),
  (title: 'Your choices', body: ['You can order as a guest without an account.', 'You can edit your name and mobile number, change your password, and delete your account in the app\'s Settings.', 'Cookies on the website are used only to keep you signed in, remember your cart and let you view your orders.']),
  (title: 'Contact', body: ['Questions about your data? Contact us using the help line shown in the app or on the website.']),
];

const List<LegalSection> termsAndConditions = [
  (title: 'About Sashroy', body: ['Sashroy (সাশ্রয়) lists medicines sold in Bangladesh, shows equivalent brands with the same generic, strength and dosage form, and lets you order them for home delivery.']),
  (title: 'Medical disclaimer', body: ['Sashroy is a price comparison and ordering service, not a doctor. Always follow your prescription and ask a registered doctor or pharmacist before switching to a different brand.', 'Equivalents share the same active ingredient, strength and form, but fillers and coatings can differ.']),
  (title: 'Prices and availability', body: ['Prices come from our catalogue and may change. The price is confirmed when we call to confirm your order.', 'Prices that look wrong are marked “price unverified”. Stock can change between ordering and packing; we will offer an equivalent or cancel the item if something runs out.']),
  (title: 'Orders, prescriptions and delivery', body: ['Some medicines need a valid prescription. We may ask for it and may cancel an order if one is required and not provided.', 'Delivery fees are shown at checkout. Please keep the cash-on-delivery amount ready and check your medicines when you receive them.']),
  (title: 'Cancellations and returns', body: ['You can ask us to cancel an order before it is out for delivery.', 'For safety, medicines cannot be returned once delivered unless they are damaged, expired or not what you ordered. Tell us within 48 hours and we will replace or refund them.']),
  (title: 'Your account', body: ['Keep your password private. You are responsible for orders placed from your account.', 'Do not misuse the service, for example by placing fake orders or trying to access other people\'s data.']),
  (title: 'Test version', body: ['The Android app is currently a test version distributed outside the Play Store. Features may change.']),
  (title: 'Changes', body: ['We may update these terms. The date at the top shows the latest version.']),
];
