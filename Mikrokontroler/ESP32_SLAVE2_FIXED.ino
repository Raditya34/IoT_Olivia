#include <Wire.h>
#include <Adafruit_ADS1X15.h>
#include <Arduino.h>


#define RXD2 16
#define TXD2 14
#define RS485_DIR 4
HardwareSerial RS485(2);


#define TRIG_PIN 5
#define ECHO_PIN 18


const float tinggiWadah = 28.0;
const float diameterWadah = 24.0;
const float radiusWadah = diameterWadah / 2.0;


long duration;
float distance;
float tinggiMinyak;
float volumeLiter;


#define SDA_PIN 21
#define SCL_PIN 22
#define TURBIDITY_CHANNEL 0
Adafruit_ADS1115 ads;
bool ads_ready = false;


#define S2 25
#define S3 26
#define sensorOut 27


// ========================================================
// KALIBRASI TERBARU TCS3200
// ========================================================
int R_Min = 95;    int R_Max = 2733;  
int G_Min = 87;    int G_Max = 3807;
int B_Min = 67;    int B_Max = 3261;  


int Red, Green, Blue;
int redValue, greenValue, blueValue;


const int pinPulse555 = 32;
volatile unsigned long pulseCount = 0;
unsigned long lastFreqCheck = 0;
float freq555 = 0.0;      
float freq555_kHz = 0.0;  
float viscosityCP = 0.0;


float ntu = 0.0;


bool system_on = false;
String current_step = "STANDBY";


// --- TIMER OPTIMALISASI NON-BLOCKING ---
unsigned long lastSensorRead = 0;
const unsigned long sensorInterval = 250;


String rs485Buffer = "";


void IRAM_ATTR countPulse() {
  pulseCount++;
}


float konversiCP(float freq_kHz) {
  float cp;
  if (freq_kHz >= 17.0) {
    cp = 67.0;
  }
  else if (freq_kHz >= 14.0 && freq_kHz < 17.0) {
    cp = (-4.252 * freq_kHz) + 149.240;
  }
  else {
    cp = (-15.597 * freq_kHz) + 347.071;
  }
  return cp;
}

float mapFloat(float x, float in_min, float in_max, float out_min, float out_max) {
  return (x - in_min) * (out_max - out_min) /  (in_max - in_min) + out_min;
}

// OPTIMALISASI: Perkecil timeout pulseIn agar tidak mengganggu RS485
int getRed() {
  digitalWrite(S2, LOW);
  digitalWrite(S3, LOW);
  return pulseIn(sensorOut, LOW, 2000); // Diturunkan ke 2ms max
}


int getGreen() {
  digitalWrite(S2, HIGH);
  digitalWrite(S3, HIGH);
  return pulseIn(sensorOut, LOW, 2000); // Diturunkan ke 2ms max
}


int getBlue() {
  digitalWrite(S2, LOW);
  digitalWrite(S3, HIGH);
  return pulseIn(sensorOut, LOW, 2000); // Diturunkan ke 2ms max
}


// Deklarasi fungsi agar compiler tahu fungsinya berada di bawah
void kirimDataKeMaster();


void setup() {
  Serial.begin(115200);
 
  pinMode(RS485_DIR, OUTPUT);
  digitalWrite(RS485_DIR, LOW);
 
  RS485.begin(9600, SERIAL_8N1, RXD2, TXD2);


  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);


  Wire.begin(SDA_PIN, SCL_PIN);
  Wire.setClock(400000);


  if (!ads.begin(0x48)) {
    Serial.println("[WARNING] ADS1115 tidak terdeteksi! Sistem menggunakan fallback.");
    ads_ready = false;
  } else {
    ads.setGain(GAIN_ONE); // 0.125mV per bit, sesuai kalibrasi turbidity terbaru
    ads_ready = true;
  }


  pinMode(S2, OUTPUT);
  pinMode(S3, OUTPUT);
  pinMode(sensorOut, INPUT);
 
  pinMode(pinPulse555, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(pinPulse555), countPulse, RISING);


  Serial.println("[SLAVE 2 READY] Sistem Auto-Transmit Aktif.");
}


void loop() {
  unsigned long currentMillis = millis();


  // ========================================================
  // 1. SAMPLING SENSOR SECARA PERIODIK (Tiap 250ms)
  // ========================================================
  if (currentMillis - lastSensorRead >= sensorInterval) {
    lastSensorRead = currentMillis;


    // A. Ultrasonik
    digitalWrite(TRIG_PIN, LOW);
    delayMicroseconds(2);
    digitalWrite(TRIG_PIN, HIGH);
    delayMicroseconds(10);
    digitalWrite(TRIG_PIN, LOW);


    duration = pulseIn(ECHO_PIN, HIGH, 15000);
    distance = (duration == 0) ? tinggiWadah : (duration * 0.0343 / 2.0);
    tinggiMinyak = tinggiWadah - distance;
    if (tinggiMinyak < 0) tinggiMinyak = 0;


    volumeLiter = (3.1416 * radiusWadah * radiusWadah * tinggiMinyak) / 1000.0;


    // B. Turbidity ADS1115 - Estimasi NTU Minyak
  if (ads_ready) {
    long totalADC = 0;
    const int samplesPerReading = 10;


    for (int i = 0; i < samplesPerReading; i++) {
      int16_t adc = ads.readADC_SingleEnded(TURBIDITY_CHANNEL);
      totalADC += adc;
      delayMicroseconds(100);
    }


    float avgADC = totalADC / (float)samplesPerReading;


    if (avgADC >= 20000) {
      // Minyak jernih: 100 - 150 NTU
      ntu = mapFloat(avgADC, 25400, 20000, 100, 150);
    }
    else if (avgADC >= 18150 && avgADC < 20000) {
      // Minyak filtrasi: 150 - 200 NTU
      ntu = mapFloat(avgADC, 19400, 18150, 150, 200);
    }
    else if (avgADC >= 15300 && avgADC < 18150) {
      // Minyak jelantah: 200 - 300 NTU
      ntu = mapFloat(avgADC, 15300, 12000, 300, 400);
    }
    else {
      // Minyak sangat jelantah / sangat kotor: 300 - 400 NTU
      ntu = mapFloat(avgADC, 15300, 12000, 300, 400);
    }


    if (ntu < 100) ntu = 100;
    if (ntu > 400) ntu = 400;
  } else {
    ntu = 0.0;
  }


    // C. Viskositas NE555
    detachInterrupt(digitalPinToInterrupt(pinPulse555));
    if (currentMillis - lastFreqCheck > 0) {
      freq555 = (pulseCount * 1000.0) / (currentMillis - lastFreqCheck);
    } else {
      freq555 = 0.0;
    }
    pulseCount = 0;
    lastFreqCheck = currentMillis;
    attachInterrupt(digitalPinToInterrupt(pinPulse555), countPulse, RISING);


    freq555_kHz = freq555 / 1000.0;
    viscosityCP = konversiCP(freq555_kHz);


    // D. RGB TCS3200
    Red = getRed();    
    redValue = (Red == 0) ? 0 : constrain(map(Red, R_Min, R_Max, 255, 0), 0, 255);


    Green = getGreen();
    greenValue = (Green == 0) ? 0 : constrain(map(Green, G_Min, G_Max, 255, 0), 0, 255);


    Blue = getBlue();  
    blueValue = (Blue == 0) ? 0 : constrain(map(Blue, B_Min, B_Max, 255, 0), 0, 255);
  }


  // ========================================================
  // 2. CEK PERINTAH MASTER
  // ========================================================
  while (RS485.available()) {
    char c = RS485.read();
    if (c == '\r') continue;


    if (c == '\n') {
        rs485Buffer.trim();
        if (rs485Buffer.length() > 0) {
            bool isClean = true;
            for (int i = 0; i < rs485Buffer.length(); i++) {
                char ch = rs485Buffer[i];
                if (ch < 32 || ch > 126) {
                    isClean = false;
                    break;
                }
            }


            if (!isClean) {
                Serial.println("[RX] Garbled bytes diabaikan");
                rs485Buffer = "";
                continue;
            }


            Serial.print("[RX] ");
            Serial.println(rs485Buffer);
            if (rs485Buffer == "CTRL:1") {
                system_on = true;
                current_step = "PROSES BERJALAN";
            } else if (rs485Buffer == "CTRL:0") {
                system_on = false;
                current_step = "STANDBY";
            } else if (rs485Buffer == "REQ:S2") {
                Serial.println("[MASTER REQUEST] Mengirim Data...");
                kirimDataKeMaster();
            }
        }
        rs485Buffer = "";
    } else {
        rs485Buffer += c;
        if (rs485Buffer.length() > 128) {
            Serial.println("[RX] Buffer overflow, reset");
            rs485Buffer = "";
        }
    }
  } // <-- FIX: Penutupan loop while() dipindah ke sini sebelum fungsi baru dimulai
}  


// ========================================================
// FUNGSI KIRIM DATA KE MASTER
// ========================================================
void kirimDataKeMaster() {
    String data = "S2:{";
    data += "\"volume_validasi\":" + String(volumeLiter, 2) + ",";
    data += "\"turbidity\":" + String(ntu, 2) + ",";
    data += "\"viscosity\":" + String(viscosityCP, 2) + ",";
    data += "\"r\":" + String(redValue) + ",";
    data += "\"g\":" + String(greenValue) + ",";
    data += "\"b\":" + String(blueValue);
    data += "}";


    Serial.println("[TX] Mengirim Data ke Master");
    Serial.println(data);


    while (RS485.available()) RS485.read();
    delay(20);


    digitalWrite(RS485_DIR, HIGH);
    delay(2);


    RS485.print(data);
    RS485.print('\n');
    RS485.flush();


    delay(5);
    digitalWrite(RS485_DIR, LOW);
    delay(2);
    while (RS485.available()) RS485.read();
}