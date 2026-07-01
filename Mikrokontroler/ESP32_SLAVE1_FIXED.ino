#include <OneWire.h>
#include <DallasTemperature.h>
#include <Arduino.h>

#define ONE_WIRE_BUS 14
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);

const int trigPin = 5;
const int echoPin = 18;

#define RXD2 16
#define TXD2 17
#define RS485_DIR 4
HardwareSerial RS485(2);

bool system_on = false;
String current_step = "STANDBY"; 
float suhu_arang = 0.0;
float suhu_bleaching = 0.0;
long duration;
float distance;
float tinggiMinyak;
float volumeLiter;

const float tinggiWadah = 29.0;
const float radiusWadah = 15.0;

// --- TIMER OPTIMALISASI NON-BLOCKING SENSOR ---
unsigned long lastSensorRead = 0;
const unsigned long sensorInterval = 200; // Baca sensor secara lokal setiap 200ms

void setup() {
  Serial.begin(115200);
  
  pinMode(RS485_DIR, OUTPUT);
  digitalWrite(RS485_DIR, LOW); 
  
  RS485.begin(9600, SERIAL_8N1, RXD2, TXD2);
  RS485.setTimeout(5); // Waktu tunggu serial sangat cepat (5ms) untuk efisiensi tinggi
  
  sensors.begin();
  sensors.setWaitForConversion(false); // OPTIMALISASI: Cegah fungsi suhu memblocking loop selama 750ms!
  
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  
  Serial.println("[SLAVE 1 READY] Polling System & Non-Blocking Sensors Active.");
}

void loop() {
  unsigned long currentMillis = millis();

  // ========================================================
  // 1. SAMPLING SENSOR SECARA PERIODIK NON-BLOCKING (Tiap 200ms)
  // ========================================================
  if (currentMillis - lastSensorRead >= sensorInterval) {
    lastSensorRead = currentMillis;

    // Ambil data suhu dari pembacaan sebelumnya
    suhu_arang = sensors.getTempCByIndex(0);
    suhu_bleaching = sensors.getTempCByIndex(1);

    if (suhu_arang == DEVICE_DISCONNECTED_C) suhu_arang = 0;
    if (suhu_bleaching == DEVICE_DISCONNECTED_C) suhu_bleaching = 0;

    // Perintahkan sensor mulai konversi suhu baru untuk loop berikutnya (Async)
    sensors.requestTemperatures();

    // Baca Ultrasonik dengan Timeout Pendek (Optimalisasi: 15000us ~ 2.5 meter maks)
    digitalWrite(trigPin, LOW); delayMicroseconds(2);
    digitalWrite(trigPin, HIGH); delayMicroseconds(10);
    digitalWrite(trigPin, LOW);

    duration = pulseIn(echoPin, HIGH, 15000); 
    distance = (duration == 0) ? tinggiWadah : (duration * 0.0343 / 2.0);

    tinggiMinyak = tinggiWadah - distance;
    if (tinggiMinyak < 0) tinggiMinyak = 0;
    if (tinggiMinyak > tinggiWadah) tinggiMinyak = tinggiWadah;

    volumeLiter = (3.1416 * radiusWadah * radiusWadah * tinggiMinyak) / 1000.0;
  }

  Serial.printf( "[S1 SENSOR] Arang=%.2f C | Bleaching=%.2f C | Volume=%.2f L\n",
                suhu_arang, suhu_bleaching, volumeLiter );

  // ========================================================
  // 2. CEK & RESPONS INSTAN PANGGILAN MASTER (REAL-TIME)
  // ========================================================
  if (RS485.available() > 0) {
    String masterCmd = RS485.readStringUntil('\n');
    masterCmd.trim();

    if (masterCmd.startsWith("REQ:S1:")) {
      int stepIdx = masterCmd.substring(7).toInt();
      system_on = true; 

      if (stepIdx == 1) current_step = "PROSES ARANG";
      else if (stepIdx == 2) current_step = "BLEACHING";
      else if (stepIdx == 3) current_step = "VALIDASI QUALITY";
      else current_step = "PROSES BERJALAN";

      // Kirim Data dengan Transisi Cepat dan Format Presisi
      digitalWrite(RS485_DIR, HIGH); 
      delayMicroseconds(50); // Jeda hardware mikrodetik yang pas

      RS485.printf("S1:{\"suhu_arang\":%.2f,\"suhu_bleaching\":%.2f,\"volume_arang\":%.2f}\n", 
                    suhu_arang, suhu_bleaching, volumeLiter);
      
      RS485.flush(); 
      delayMicroseconds(200); // Jeda aman melepas bus
      digitalWrite(RS485_DIR, LOW); 

      // Cetak log ke serial lokal setelah transmisi selesai agar tidak mengganggu komunikasi
      Serial.printf("[TX S1] Sent -> Arang: %.2f C, Vol: %.2f L (Step %d)\n", suhu_arang, volumeLiter, stepIdx);
    }
    else if (masterCmd.startsWith("CTRL:0")) {
      system_on = false;
      current_step = "STANDBY";
    }
  }
}