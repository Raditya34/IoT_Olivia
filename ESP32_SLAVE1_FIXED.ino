#include <OneWire.h>
#include <DallasTemperature.h>
#include <Arduino.h>

// ===============================
// PIN DS18B20
// ===============================
#define ONE_WIRE_BUS 14
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);

// ===============================
// PIN HC-SR04
// ===============================
const int trigPin = 5;
const int echoPin = 18;

// ===============================
// PIN RS485
// ===============================
#define RXD2 16
#define TXD2 17
#define RS485_DIR 4
HardwareSerial RS485(2);

// ===============================
// DATA DIMENSI WADAH
// ===============================
const float tinggiWadah = 29.0;     // cm
const float diameterWadah = 30.0;   // cm
const float radiusWadah = diameterWadah / 2.0;

// Variabel sensor
long duration;
float distance;
float tinggiMinyak;
float volumeLiter;
float suhu_arang = 0.0;
float suhu_bleaching = 0.0;

unsigned long lastSendTime = 0;
const unsigned long sendInterval = 3000; // Kirim tiap 3 detik

void setup() {
  Serial.begin(115200);
  sensors.begin();

  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);

  pinMode(RS485_DIR, OUTPUT);
  digitalWrite(RS485_DIR, LOW);
  RS485.begin(9600, SERIAL_8N1, RXD2, TXD2);

  Serial.println("=========================================");
  Serial.println("  SLAVE 1: READY (SENSOR FISIK ASLI)");
  Serial.println("=========================================");
}

void loop() {
  unsigned long currentMillis = millis();
  if (currentMillis - lastSendTime < sendInterval) {
    return;
  }
  lastSendTime = currentMillis;

  // 1. BACA SUHU DS18B20
  sensors.requestTemperatures();
  suhu_arang = sensors.getTempCByIndex(0);
  suhu_bleaching = sensors.getTempCByIndex(1);

  if (suhu_arang == DEVICE_DISCONNECTED_C) suhu_arang = 0;
  if (suhu_bleaching == DEVICE_DISCONNECTED_C) suhu_bleaching = 0;

  // 2. BACA ULTRASONIK HC-SR04
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  duration = pulseIn(echoPin, HIGH, 30000);
  distance = duration * 0.0343 / 2.0;

  tinggiMinyak = tinggiWadah - distance;
  if (tinggiMinyak < 0) tinggiMinyak = 0;
  if (tinggiMinyak > tinggiWadah) tinggiMinyak = tinggiWadah;

  // 3. HITUNG VOLUME
  volumeLiter = (3.1416 * radiusWadah * radiusWadah * tinggiMinyak) / 1000.0;

  // 4. BENTUK PAYLOAD JSON
  String payload = "{\"suhu_arang\":" + String(suhu_arang, 2) +
                   ",\"suhu_bleaching\":" + String(suhu_bleaching, 2) +
                   ",\"tinggi\":" + String(tinggiMinyak, 2) +
                   ",\"volume_arang\":" + String(volumeLiter, 2) + "}";

  // 5. KIRIM DATA VIA RS485
  digitalWrite(RS485_DIR, HIGH); // Mode Transmit
  delay(5);
  RS485.print("S1:");
  RS485.println(payload);
  RS485.flush();
  delay(5);
  digitalWrite(RS485_DIR, LOW); // Mode Receive

  Serial.print("S1 Kirim: ");
  Serial.println(payload);
}
