#include <Wire.h>
#include <MPU6050.h>
#include "MAX30105.h"
#include "heartRate.h"
#include "BluetoothSerial.h"

// ================= OBJECTS =================
MPU6050 mpu;
MAX30105 max30102;
BluetoothSerial SerialBT;

// ================= PINS =================
#define FSR_PIN 35
#define MIC_PIN 34

// ================= MPU6050 =================
long ax_off, ay_off, az_off;
float ax_f = 0, ay_f = 0, az_f = 0;
const float alpha = 0.8;

// ================= HEART RATE =================
long lastBeat = 0;
float bpm = 0, bpmAvg = 0;

#define RR_SIZE 20
unsigned long rrIntervals[RR_SIZE];
int rrIndex = 0;
bool rrFilled = false;

// ================= RESPIRATION =================
unsigned long lastBreath = 0;
float respirationRPM = 0;
int fsrThreshold = 2000;

// ================= FUNCTIONS =================

void calibrateMPU() {
  const int N = 300;
  long ax = 0, ay = 0, az = 0;

  Serial.println("Calibrating MPU6050...");
  SerialBT.println("Calibrating MPU6050...");

  for (int i = 0; i < N; i++) {
    int16_t axr, ayr, azr, gxr, gyr, gzr;
    mpu.getMotion6(&axr, &ayr, &azr, &gxr, &gyr, &gzr);
    ax += axr; ay += ayr; az += azr;
    delay(5);
  }

  ax_off = ax / N;
  ay_off = ay / N;
  az_off = az / N;

  Serial.println("MPU calibration done");
  SerialBT.println("MPU calibration done");
}

float computeRMSSD() {
  if (!rrFilled) return 0;
  float sum = 0;
  for (int i = 1; i < RR_SIZE; i++) {
    float diff = rrIntervals[i] - rrIntervals[i - 1];
    sum += diff * diff;
  }
  return sqrt(sum / (RR_SIZE - 1));
}

void updateRespiration(int fsrValue) {
  unsigned long now = millis();
  if (fsrValue > fsrThreshold && (now - lastBreath) > 800) {
    respirationRPM = 60000.0 / (now - lastBreath);
    lastBreath = now;
  }
}

int computeStressScore(float bpm, float rmssd, float rpm, float accelMag, int mic) {
  int score = 0;

  if (bpm > 130) score += 2;
  else if (bpm > 100) score += 1;

  if (rmssd < 25) score += 2;
  else if (rmssd < 50) score += 1;

  if (rpm > 30) score += 2;
  else if (rpm > 20) score += 1;

  if (accelMag > 1.5) score += 2;
  else if (accelMag > 0.2) score += 1;

  if (mic > 600) score += 2;
  else if (mic > 300) score += 1;

  return score;
}

String getChildState(int score) {
  if (score >= 6) return "CRISIS";
  if (score >= 3) return "STRESSED";
  return "CALM";
}

// ================= SETUP =================
void setup() {
  Serial.begin(115200);
  delay(2000);

  SerialBT.begin("ESP32_CHILD_MONITOR");

  Wire.begin(21, 22);
  Wire.setClock(400000);

  mpu.initialize();
  calibrateMPU();

  if (!max30102.begin(Wire, I2C_SPEED_FAST)) {
    Serial.println("MAX30102 NOT FOUND");
    SerialBT.println("MAX30102 NOT FOUND");
    while (1);
  }

  max30102.setup(0x1F, 4, 2, 100, 411, 4096);
  max30102.setPulseAmplitudeIR(0xFF);
  max30102.setPulseAmplitudeRed(0x00);

  Serial.println("SYSTEM READY");
  SerialBT.println("SYSTEM READY");
}

// ================= LOOP =================
void loop() {

  int16_t axr, ayr, azr, gxr, gyr, gzr;
  mpu.getMotion6(&axr, &ayr, &azr, &gxr, &gyr, &gzr);

  float ax = axr - ax_off;
  float ay = ayr - ay_off;
  float az = azr - az_off;

  ax_f = alpha * ax_f + (1 - alpha) * ax;
  ay_f = alpha * ay_f + (1 - alpha) * ay;
  az_f = alpha * az_f + (1 - alpha) * az;

  float accelMag = sqrt(ax_f * ax_f + ay_f * ay_f + az_f * az_f);
  if (accelMag < 0.15) accelMag = 0;

  int fsrValue = analogRead(FSR_PIN);
  updateRespiration(fsrValue);

  long micSum = 0;
  for (int i = 0; i < 100; i++) {
    micSum += analogRead(MIC_PIN);
    delayMicroseconds(200);
  }
  int micLevel = micSum / 100;

  long irValue = max30102.getIR();
  if (irValue > 15000 && checkForBeat(irValue)) {
    unsigned long delta = millis() - lastBeat;
    lastBeat = millis();
    bpm = 60.0 / (delta / 1000.0);

    if (bpm > 40 && bpm < 200) {
      bpmAvg = 0.8 * bpmAvg + 0.2 * bpm;
      rrIntervals[rrIndex++] = delta;
      if (rrIndex >= RR_SIZE) {
        rrIndex = 0;
        rrFilled = true;
      }
    }
  }

  float rmssd = computeRMSSD();
  int stressScore = computeStressScore(bpmAvg, rmssd, respirationRPM, accelMag, micLevel);
  String state = getChildState(stressScore);

  // ===== OUTPUT =====
  String output =
    "RPM=" + String(respirationRPM,1) +
    " BPM=" + String(bpmAvg,1) +
    " RMSSD=" + String(rmssd,1) +
    " ACC=" + String(accelMag,2) +
    " MIC=" + String(micLevel) +
    " SCORE=" + String(stressScore) +
    " STATE=" + state;

  Serial.println(output);
  SerialBT.println(output);

  delay(300);
}
 

