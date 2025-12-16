const admin = require('firebase-admin');

// TODO: download a service account key JSON from Firebase console (Project settings → Service accounts)
admin.initializeApp({
  credential: admin.credential.cert(require('./serviceAccountKey.json')),
});

const db = admin.firestore();

const userId = '76Vn4wV3WXSZWIYOUsuEQebtBVB3';
const baseDate = new Date('2025-12-8');

const testData = [
  { maxHeartRate: 78.0, avgBreathingRate: 18.5, maxNoise: 48.0, maxMovement: 32.0 },
  { maxHeartRate: 85.0, avgBreathingRate: 20.0, maxNoise: 55.0, maxMovement: 40.0 },
  { maxHeartRate: 95.0, avgBreathingRate: 24.0, maxNoise: 68.0, maxMovement: 55.0 },
  { maxHeartRate: 115.0, avgBreathingRate: 32.0, maxNoise: 85.0, maxMovement: 75.0 },
  { maxHeartRate: 135.0, avgBreathingRate: 38.0, maxNoise: 105.0, maxMovement: 92.0 },
  { maxHeartRate: 88.0, avgBreathingRate: 22.0, maxNoise: 60.0, maxMovement: 45.0 },
  { maxHeartRate: 75.0, avgBreathingRate: 17.5, maxNoise: 42.0, maxMovement: 28.0 },
];

// BROWSER CONSOLE VERSION (copy and paste into Firebase Console → Firestore → Data tab → F12 → Console)
console.log('Copy and paste this into Firebase Console browser:');
console.log(`
const db = firebase.firestore();
const userId = '${userId}';
const baseDate = new Date('${baseDate.toISOString().split('T')[0]}');

const testData = ${JSON.stringify(testData, null, 2)};

testData.forEach((data, index) => {
  const date = new Date(baseDate);
  date.setDate(date.getDate() + index);
  const dateKey = date.toISOString().split('T')[0];

  db.collection('users')
    .doc(userId)
    .collection('daily_stats')
    .doc(dateKey)
    .set({
      date: firebase.firestore.Timestamp.fromDate(date),
      ...data,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
    })
    .then(() => console.log('✅ Created daily_stats for', dateKey))
    .catch(err => console.error('❌ Error for', dateKey, err));
});

console.log('Script executed - check Firestore for new documents');
`);

// NODE VERSION (requires serviceAccountKey.json)
async function seed() {
  for (let i = 0; i < testData.length; i++) {
    const data = testData[i];
    const date = new Date(baseDate);
    date.setDate(date.getDate() + i);
    const dateKey = date.toISOString().split('T')[0];

    await db
      .collection('users')
      .doc(userId)
      .collection('daily_stats')
      .doc(dateKey)
      .set({
        date: admin.firestore.Timestamp.fromDate(date),
        ...data,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    console.log('Created daily_stats for', dateKey);
  }
  process.exit(0);
}

seed().catch(err => {
 console.error(err);
 process.exit(1);
});