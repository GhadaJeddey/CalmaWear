// seed_alerts.js
const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(require('./serviceAccountKey.json')),
});

const db = admin.firestore();

const userId = '76Vn4wV3WXSZWIYOUsuEQebtBVB3'; // Your user ID
const startDate = new Date('2025-12-10'); // Starting date

// Function to generate random alert data
function generateRandomAlert(date) {
  const alertTime = new Date(date);
  
  // Random hour between 8 AM and 8 PM
  const hour = 8 + Math.floor(Math.random() * 12);
  const minute = Math.floor(Math.random() * 60);
  alertTime.setHours(hour, minute, 0, 0);
  
  // Generate random stress score (75-100 for alerts)
  const stressScore = 75 + Math.floor(Math.random() * 26);
  
  return {
    stressScore: stressScore,
    timestamp: admin.firestore.Timestamp.fromDate(alertTime),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

async function seedAlerts() {
  console.log('🚀 Seeding alert data for user:', userId);
  console.log('='.repeat(50));
  
  const batch = db.batch();
  let alertCount = 0;
  
  // Generate alerts for the last 7 days
  for (let day = 0; day < 7; day++) {
    const currentDate = new Date(startDate);
    currentDate.setDate(currentDate.getDate() + day);
    const dateStr = currentDate.toISOString().split('T')[0];
    
    // Generate 0-3 alerts per day (random)
    const alertsPerDay = Math.floor(Math.random() * 4); // 0, 1, 2, or 3 alerts
    
    console.log(`📅 ${dateStr}: Generating ${alertsPerDay} alert(s)`);
    
    for (let i = 0; i < alertsPerDay; i++) {
      const alertData = generateRandomAlert(currentDate);
      const alertId = `${dateStr}_alert_${i}`;
      
      const alertRef = db
        .collection('users')
        .doc(userId)
        .collection('alerts')
        .doc(alertId);
      
      batch.set(alertRef, alertData);
      alertCount++;
      
      console.log(`   🚨 Alert ${i}: ${alertData.stressScore}% stress at ${alertData.timestamp.toDate().toLocaleTimeString()}`);
    }
  }
  
  // Commit the batch
  await batch.commit();
  
  console.log('='.repeat(50));
  console.log(`✅ Successfully seeded ${alertCount} alerts for user ${userId}`);
  console.log('🎉 Alert data is now ready for crisis history chart!');
  
  process.exit(0);
}

// Run the seeding
seedAlerts().catch((error) => {
  console.error('❌ Error seeding alerts:', error);
  process.exit(1);
});