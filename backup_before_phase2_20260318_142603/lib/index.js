const admin = require('firebase-admin');
const serviceAccount = require('./path/to/your/serviceAccountKey.json'); // Path to the downloaded service account JSON file

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://farmkart-89ddd-default-rtdb.firebaseio.com', // Your Realtime Database URL
});

// Get a reference to your Firebase Realtime Database
const db = admin.database();

// Example: Writing data to the Realtime Database
const ref = db.ref('itemsForSale');
ref.set({
  item1: {
    productName: 'Product 1',
    description: 'Description of Product 1',
    price: '100.00',
  },
  item2: {
    productName: 'Product 2',
    description: 'Description of Product 2',
    price: '200.00',
  },
})
.then(() => {
  console.log('Data saved successfully');
})
.catch((error) => {
  console.error('Error saving data:', error);
});

// Example: Reading data from the Realtime Database
ref.once('value', (snapshot) => {
  console.log(snapshot.val());
});
