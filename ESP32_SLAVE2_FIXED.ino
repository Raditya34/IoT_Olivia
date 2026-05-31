#include <Wire.h>
#include <Adafruit_ADS1X15.h>
#include <Arduino.h>

#define RXD2 16
#define TXD2 17
#define RS485_DIR 4
HardwareSerial RS485(2);

// ======================
// HC-SR04 VOLUME MINYAK
// ======================
#define TRIG_PIN 5
#define ECHO_PIN 18

const float tinggiWadah = 29.0;
const float diameterWadah = 30.0;
const float radiusWadah = diameterWadah / 2.0;

long duration;
float distance;
float tinggiMinyak;
float volumeLiter;

// ======================
// ADS1115 TURBIDITY
// ======================
#define SDA_PIN 21
#define SCL_PIN 22
#define TURBIDITY_CHANNEL 0

Adafruit_ADS1115 ads;
const int samplesPerReading = 10;

// ======================
// TCS3200 RGB
// ======================
#define S2 25
#define S3 26
#define sensorOut 27

int R_Min = 40;
int R_Max = 580;
int G_Min = 40;
int G_Max = 647;
int B_Min = 28;
int B_Max = 523;

int Red, Green, Blue;
int redValue, greenValue, blueValue;

// ======================
// VISKOSITAS
// ======================
#define PIN_555 32

volatile unsigned long count555 = 0;
unsigned long lastFreqTime = 0;

void IRAM_ATTR isr555() {
  count555++;
}

float mapFloat(float x, float in_min, float in_max, float out_min, float out_max) {
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

int getRed() {
  digitalWrite(S2, LOW);
  digitalWrite(S3, LOW);
  return pulseIn(sensorOut, LOW);
}

int getGreen() {
  digitalWrite(S2, HIGH);
  digitalWrite(S3, HIGH);
  return pulseIn(sensorOut, LOW);
}

int getBlue() {
  digitalWrite(S2, LOW);
  digitalWrite(S3, HIGH);
  return pulseIn(sensorOut, LOW);
}

unsigned long lastSendTime = 0;
const unsigned long sendInterval = 3000;
bool system_on = false;

void setup() {
  Serial.begin(115200);

  pinMode(RS485_DIR, OUTPUT);
  digitalWrite(RS485_DIR, LOW);
  RS485.begin(9600, SERIAL_8N1, RXD2, TXD2);

  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);

  pinMode(S2, OUTPUT);
  pinMode(S3, OUTPUT);
  pinMode(sensorOut, INPUT);

  pinMode(PIN_555, INPUT);
  attachInterrupt(digitalPinToInterrupt(PIN_555), isr555, RISING);

  Wire.begin(SDA_PIN, SCL_PIN);
  if (!ads.begin(0x48)) {
    Serial.println("ADS1115 gagal!");
    while (1);
  }
  ads.setGain(GAIN_ONE);
  lastFreqTime = millis();

  Serial.println("=========================================");
  Serial.println("  SLAVE 2: READY (LOGIKA SENSOR OPTIMAL)");
  Serial.println("=========================================");
}

void loop() {
  // Proses command masuk via RS485 (jika ada)
  if (RS485.available() > 0) {
    String raw = RS485.readStringUntil('\n');
    raw.trim();
    if (raw.startsWith("CTRL:")) {
      String v = raw.substring(5);
      if (v == "1") { system_on = true; Serial.println("[CMD] SYSTEM ON (via RS485)"); }
      else if (v == "0") { system_on = false; Serial.println("[CMD] SYSTEM OFF (via RS485)"); }
    }
  }

  unsigned long currentMillis = millis();
  if (currentMillis - lastSendTime < sendInterval) {
    return;
  }
  lastSendTime = currentMillis;

  // 1. HC-SR04 VOLUME
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  duration = pulseIn(ECHO_PIN, HIGH, 30000);
  distance = duration * 0.0343 / 2.0;
  tinggiMinyak = tinggiWadah - distance;
  if (tinggiMinyak < 0) tinggiMinyak = 0;
  if (tinggiMinyak > tinggiWadah) tinggiMinyak = tinggiWadah;
  volumeLiter = (3.1416 * radiusWadah * radiusWadah * tinggiMinyak) / 1000.0;

  // 2. FREKUENSI VISKOSITAS
  unsigned long now = millis();
  noInterrupts();
  float freq555 = count555 * (1000.0 / (now - lastFreqTime));
  count555 = 0;
  lastFreqTime = now;
  interrupts();

  // 3. TURBIDITY ADS1115
  long totalADC = 0;
  for (int i = 0; i < samplesPerReading; i++) {
    totalADC += ads.readADC_SingleEnded(TURBIDITY_CHANNEL);
    delay(5);
  }
  float avgADC = totalADC / (float)samplesPerReading;
  float ntu;

  if (avgADC >= 7000)
    ntu = mapFloat(avgADC, 11000, 7000, 100, 150);
  else if (avgADC >= 6000)
    ntu = mapFloat(avgADC, 7000, 6000, 150, 200);
  else if (avgADC >= 4800)
    ntu = mapFloat(avgADC, 6000, 4800, 200, 300);
  else
    ntu = mapFloat(avgADC, 4800, 3000, 300, 400);

  if (ntu < 100) ntu = 100;
  if (ntu > 400) ntu = 400;

  // 4. RGB TCS3200
  Red = getRed();
  redValue = constrain(map(Red, R_Min, R_Max, 255, 0), 0, 255);
  delay(50);
  Green = getGreen();
  greenValue = constrain(map(Green, G_Min, G_Max, 255, 0), 0, 255);
  delay(50);
  Blue = getBlue();
  blueValue = constrain(map(Blue, B_Min, B_Max, 255, 0), 0, 255);
  delay(50);

  // 5. BENTUK PAYLOAD JSON MATCHING MASTER
  String payload = "{\"volume\":" + String(volumeLiter, 2) +
                   ",\"tinggi\":" + String(tinggiMinyak, 2) +
                   ",\"ntu\":" + String(ntu, 2) +
                   ",\"r\":" + String(redValue) +
                   ",\"g\":" + String(greenValue) +
                   ",\"b\":" + String(blueValue) +
                   ",\"freq\":" + String(freq555 / 1000.0, 3) + "}";

  // 6. KIRIM RS485
  digitalWrite(RS485_DIR, HIGH);
  delay(5);
  RS485.print("S2:");
  RS485.println(payload);
  RS485.flush();
  delay(5);
  digitalWrite(RS485_DIR, LOW);

  Serial.println("\n========= [DATA TERKIRIM DARI SLAVE 2] =========");
  Serial.print("Volume Validasi : "); Serial.print(volumeLiter, 2); Serial.println(" Liter");
  Serial.print("Kekeruhan (NTU) : "); Serial.println(ntu, 2);
  Serial.print("Warna RGB       : "); Serial.printf("R:%d, G:%d, B:%d\n", redValue, greenValue, blueValue);
  Serial.print("Freq Viskositas : "); Serial.print(freq555 / 1000.0, 3); Serial.println(" kHz");
  Serial.print("Payload RS485   : S2:"); Serial.println(payload);
  Serial.println("=================================================");
}
