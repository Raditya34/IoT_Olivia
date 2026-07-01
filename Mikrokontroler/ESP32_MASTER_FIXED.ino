/*
 ==============================================================================
             KODE EMBEDDED UTAMA: ESP32 MASTER (OLIVIA IoT SYSTEM)
 ==============================================================================
 Fitur terintegrasi:
 - FSM Aktuator Active-LOW & Dimmer Control Zero-Cross.
 - Fuzzy Logic Terkomputasi 40 Rules (Library eFLL / Mamdani Inference).
 - Sistem Berjalan Berurutan Berdasarkan Timer (Tanpa Interupsi Fail-Safe).
 - MQTT HiveMQ Cloud & API Laravel
 - RS485 Multiprocessor Communication
 ==============================================================================
*/
#include "soc/soc.h"
#include "soc/rtc_cntl_reg.h"
#include "soc/gpio_reg.h"
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <Fuzzy.h> // Library eFLL

#if __has_include("esp_ron=m_sys.h")
#include "esp_rom_sys.h"
#define DELAY_US esp_rom_delay_us
  #else
#define DELAY_US ets_delay_us
#endif

// ============================================================================
// CONFIG: KREDENSIAL WIFI & MQTT
// ============================================================================
const char* ssid     = "YASMIN";  
const char* password = "yasmin1701";

const char* mqtt_server    = "a24e7a00b6d943c2be69eafa2c60943f.s1.eu.hivemq.cloud";  
const int mqtt_port        = 8883;  
const char* mqtt_user      = "Olivia_IoT";  
const char* mqtt_pass      = "Olivia12345";  
const char* mqtt_client_id = "esp32_master_olivia";

const char* topic_publish      = "olivia/OLIVIA-MASTER/telemetry";  
const char* topic_sub_control  = "olivia/control";  

const String laravel_base_url  = "https://iotolivia-production.up.railway.app/api/";

WiFiClientSecure espClient;  
PubSubClient client(espClient);

unsigned long lastMqttRetry   = 0;  
unsigned long lastWifiCheck   = 0;  
unsigned long lastPublishTime = 0;  
const unsigned long publishInterval = 3000; 

// ============================================================================
// CONFIG: PIN HARDWARE & RS485
// ============================================================================
#define RXD2 16  
#define TXD2 17
#define RS485_DIR 4 

// Valve
#define RELAY_OPEN      27
#define RELAY_CLOSE     32
// Pump
#define RELAY_PUMP1     18
#define RELAY_PUMP2     19
#define RELAY_PUMP3     14
// Heater
#define RELAY_HEATER1   22
#define RELAY_HEATER2   23
// Motor
#define RELAY_MOTOR     26
// Dimmer
#define ZC_PIN          33
#define TRIAC_PIN       25
// Switch
#define SWITCH_PIN      13

// ============================================================================
// CONFIG: TIMER & STATE MACHINE
// ============================================================================
const unsigned long HEATER1_DELAY     = 7200000;
const unsigned long VALVE_OPEN_TIME   = 20000;
const unsigned long VALVE_WAIT_TIME   = 180000;
const unsigned long VALVE_CLOSE_TIME  = 20000;
const unsigned long DELAY_TIME        = 5000;
const unsigned long DELAY_FUZZY_TIME  = 1800000;
const unsigned long PUMP1_TIME        = 90000;
const unsigned long PUMP2_TIME        = 165000;
const unsigned long PUMP3_TIME        = 60000;
const unsigned long MOTOR_TIME        = 60000;
const unsigned long BLEACHING_TIME    = 10800000;
const unsigned long HEATER_ON_TIME    = 15000;
const unsigned long HEATER_OFF_TIME   = 10000;
const float SET_POINT                 = 70.0;

enum STATE {
  START, HEATER1_RUN, FILTER_DELAY, VALVE_OPEN, VALVE_WAIT, VALVE_CLOSE,
  DELAY_PUMP1, PUMP1_RUN, DELAY_HEATER2, HEATER2_RUN, MOTOR_RUN,
  FILTER_BLEACHING, DELAY_PUMP2, PUMP2_RUN, DELAY_PUMP3, PUMP3_RUN, FINISH
};
STATE state = FINISH;

unsigned long timer;
unsigned long heaterTimer;
bool heaterStatus = false;
volatile bool motorDimmerEnable = false;
volatile int currentDelay = 2000;
const int TRIAC_PULSE_US = 50;

// Variables Global IoT
bool system_on = false;
String current_step = "STANDBY";
int process_step = 0;
float suhu_arang = 0.0, volume_arang = 0.0;
float suhu_bleaching = 27.0; 
float volume_validasi = 0.0, turbidity = 0.0, viscosity = 0.0;
int redValue = 0, greenValue = 0, blueValue = 0;
float kelayakan = 0.0;
String status_layak = "TIDAK LAYAK";

// --- LOGIKA POLLING RS485 MASTER ---
unsigned long lastPollTime = 0;
const unsigned long pollInterval = 1000; 
int pollStage = 0;                       
String rs485Buffer = "";
uint8_t lastSlaveReceived = 0;

// --- KONFIGURASI TOMBOL FISIK ---
const int pinSwitch = 13; 
bool lastSwitchState = HIGH; 

// ============================================================================
// INIT eFLL FUZZY LOGIC
// ============================================================================
Fuzzy *fuzzy = new Fuzzy();

void setupFuzzy() {
  // --- INPUT 1: TURBIDITY ---
  FuzzyInput *turbidityInput = new FuzzyInput(1);
  FuzzySet *sangatJernih = new FuzzySet(0, 0, 100, 136);
  FuzzySet *jernih = new FuzzySet(135, 165, 165, 205);
  FuzzySet *keruh = new FuzzySet(204, 245, 245, 286);
  FuzzySet *sangatKeruh = new FuzzySet(285, 305, 500, 500);
  turbidityInput->addFuzzySet(sangatJernih);
  turbidityInput->addFuzzySet(jernih);
  turbidityInput->addFuzzySet(keruh);
  turbidityInput->addFuzzySet(sangatKeruh);
  fuzzy->addFuzzyInput(turbidityInput);

  // --- INPUT 2: VISKOSITAS ---
  FuzzyInput *viskositasInput = new FuzzyInput(2);
  FuzzySet *encer = new FuzzySet(0, 0, 50, 80);
  FuzzySet *sedang = new FuzzySet(75, 95, 95, 120);
  FuzzySet *kental = new FuzzySet(100, 140, 140, 180);
  FuzzySet *sangatKental = new FuzzySet(160, 180, 200, 200);
  viskositasInput->addFuzzySet(encer);
  viskositasInput->addFuzzySet(sedang);
  viskositasInput->addFuzzySet(kental);
  viskositasInput->addFuzzySet(sangatKental);
  fuzzy->addFuzzyInput(viskositasInput);

  // --- INPUT 3: WARNA (RED CHANNEL) ---
  FuzzyInput *warnaInput = new FuzzyInput(3);
  FuzzySet *kuningCerah = new FuzzySet(214, 231, 255, 255);
  FuzzySet *kuningKecoklatan = new FuzzySet(170, 195, 195, 215);
  FuzzySet *coklat = new FuzzySet(100, 135, 135, 171);
  FuzzySet *coklatPekat = new FuzzySet(0, 0, 90, 101);
  warnaInput->addFuzzySet(kuningCerah);
  warnaInput->addFuzzySet(kuningKecoklatan);
  warnaInput->addFuzzySet(coklat);
  warnaInput->addFuzzySet(coklatPekat);
  fuzzy->addFuzzyInput(warnaInput);

  // --- OUTPUT: KUALITAS KELAYAKAN ---
  FuzzyOutput *kualitas = new FuzzyOutput(1);
  FuzzySet *tidakLayak = new FuzzySet(0, 0, 25, 41);
  FuzzySet *kurangLayak = new FuzzySet(35, 55, 55, 75);
  FuzzySet *layak = new FuzzySet(70, 80, 80, 90);
  FuzzySet *sangatLayak = new FuzzySet(85, 95, 100, 100);
  kualitas->addFuzzySet(tidakLayak);
  kualitas->addFuzzySet(kurangLayak);
  kualitas->addFuzzySet(layak);
  kualitas->addFuzzySet(sangatLayak);
  fuzzy->addFuzzyOutput(kualitas);

  // --- CONSEQUENTS ---
  FuzzyRuleConsequent *THEN_TIDAK = new FuzzyRuleConsequent();
  THEN_TIDAK->addOutput(tidakLayak);
  FuzzyRuleConsequent *THEN_KURANG = new FuzzyRuleConsequent();
  THEN_KURANG->addOutput(kurangLayak);
  FuzzyRuleConsequent *THEN_LAYAK = new FuzzyRuleConsequent();
  THEN_LAYAK->addOutput(layak);
  FuzzyRuleConsequent *THEN_SANGAT = new FuzzyRuleConsequent();
  THEN_SANGAT->addOutput(sangatLayak);

  int nomorRule = 1;

  // RULE 1 - 40
  FuzzyRuleAntecedent *r1a = new FuzzyRuleAntecedent(); r1a->joinWithAND(kuningCerah, sangatJernih);
  FuzzyRuleAntecedent *r1 = new FuzzyRuleAntecedent(); r1->joinWithAND(r1a, encer);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r1, THEN_SANGAT));

  FuzzyRuleAntecedent *r2a = new FuzzyRuleAntecedent(); r2a->joinWithAND(kuningCerah, sangatJernih);
  FuzzyRuleAntecedent *r2 = new FuzzyRuleAntecedent(); r2->joinWithAND(r2a, sedang);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r2, THEN_SANGAT));

  FuzzyRuleAntecedent *r3a = new FuzzyRuleAntecedent(); r3a->joinWithAND(kuningCerah, jernih);
  FuzzyRuleAntecedent *r3 = new FuzzyRuleAntecedent(); r3->joinWithAND(r3a, encer);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r3, THEN_SANGAT));

  FuzzyRuleAntecedent *r4a = new FuzzyRuleAntecedent(); r4a->joinWithAND(kuningCerah, jernih);
  FuzzyRuleAntecedent *r4 = new FuzzyRuleAntecedent(); r4->joinWithAND(r4a, sedang);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r4, THEN_SANGAT));

  FuzzyRuleAntecedent *r5 = new FuzzyRuleAntecedent(); r5->joinWithAND(kuningCerah, encer);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r5, THEN_SANGAT));

  FuzzyRuleAntecedent *r6 = new FuzzyRuleAntecedent(); r6->joinWithAND(kuningCerah, sangatJernih);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r6, THEN_SANGAT));

  FuzzyRuleAntecedent *r7 = new FuzzyRuleAntecedent(); r7->joinWithAND(kuningCerah, jernih);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r7, THEN_SANGAT));

  FuzzyRuleAntecedent *r8 = new FuzzyRuleAntecedent(); r8->joinWithAND(kuningCerah, sedang);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r8, THEN_SANGAT));

  FuzzyRuleAntecedent *r9 = new FuzzyRuleAntecedent(); r9->joinWithAND(kuningCerah, keruh);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r9, THEN_LAYAK));

  FuzzyRuleAntecedent *r10 = new FuzzyRuleAntecedent(); r10->joinWithAND(kuningCerah, sangatKeruh);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r10, THEN_LAYAK));

  FuzzyRuleAntecedent *r11 = new FuzzyRuleAntecedent(); r11->joinWithAND(kuningCerah, kental);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r11, THEN_LAYAK));

  FuzzyRuleAntecedent *r12 = new FuzzyRuleAntecedent(); r12->joinWithAND(kuningCerah, sangatKental);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r12, THEN_LAYAK));

  FuzzyRuleAntecedent *r13 = new FuzzyRuleAntecedent(); r13->joinWithAND(kuningKecoklatan, sangatJernih);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r13, THEN_LAYAK));

  FuzzyRuleAntecedent *r14 = new FuzzyRuleAntecedent(); r14->joinWithAND(kuningKecoklatan, jernih);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r14, THEN_LAYAK));

  FuzzyRuleAntecedent *r15 = new FuzzyRuleAntecedent(); r15->joinWithAND(kuningKecoklatan, keruh);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r15, THEN_LAYAK));

  FuzzyRuleAntecedent *r16 = new FuzzyRuleAntecedent(); r16->joinWithAND(kuningKecoklatan, encer);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r16, THEN_LAYAK));

  FuzzyRuleAntecedent *r17 = new FuzzyRuleAntecedent(); r17->joinWithAND(kuningKecoklatan, sedang);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r17, THEN_LAYAK));

  FuzzyRuleAntecedent *r18 = new FuzzyRuleAntecedent(); r18->joinWithAND(kuningKecoklatan, kental);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r18, THEN_LAYAK));

  FuzzyRuleAntecedent *r19a = new FuzzyRuleAntecedent(); r19a->joinWithAND(kuningKecoklatan, sangatKeruh);
  FuzzyRuleAntecedent *r19 = new FuzzyRuleAntecedent(); r19->joinWithAND(r19a, kental);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r19, THEN_LAYAK));

  FuzzyRuleAntecedent *r20a = new FuzzyRuleAntecedent(); r20a->joinWithAND(kuningKecoklatan, keruh);
  FuzzyRuleAntecedent *r20 = new FuzzyRuleAntecedent(); r20->joinWithAND(r20a, sangatKental);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r20, THEN_LAYAK));

  FuzzyRuleAntecedent *r21 = new FuzzyRuleAntecedent(); r21->joinWithAND(coklat, jernih);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r21, THEN_KURANG));

  FuzzyRuleAntecedent *r22 = new FuzzyRuleAntecedent(); r22->joinWithAND(coklat, keruh);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r22, THEN_KURANG));

  FuzzyRuleAntecedent *r23 = new FuzzyRuleAntecedent(); r23->joinWithAND(coklat, sangatKeruh);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r23, THEN_KURANG));

  FuzzyRuleAntecedent *r24 = new FuzzyRuleAntecedent(); r24->joinWithAND(coklat, sedang);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r24, THEN_KURANG));

  FuzzyRuleAntecedent *r25 = new FuzzyRuleAntecedent(); r25->joinWithAND(coklat, kental);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r25, THEN_KURANG));

  FuzzyRuleAntecedent *r26 = new FuzzyRuleAntecedent(); r26->joinWithAND(coklat, sangatKental);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r26, THEN_KURANG));

  FuzzyRuleAntecedent *r27a = new FuzzyRuleAntecedent(); r27a->joinWithAND(coklat, keruh);
  FuzzyRuleAntecedent *r27 = new FuzzyRuleAntecedent(); r27->joinWithAND(r27a, kental);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r27, THEN_KURANG));

  FuzzyRuleAntecedent *r28a = new FuzzyRuleAntecedent(); r28a->joinWithAND(coklat, sangatKeruh);
  FuzzyRuleAntecedent *r28 = new FuzzyRuleAntecedent(); r28->joinWithAND(r28a, kental);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r28, THEN_KURANG));

  FuzzyRuleAntecedent *r29 = new FuzzyRuleAntecedent(); r29->joinSingle(coklatPekat);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r29, THEN_TIDAK));

  FuzzyRuleAntecedent *r30 = new FuzzyRuleAntecedent(); r30->joinWithAND(coklatPekat, sangatKeruh);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r30, THEN_TIDAK));

  FuzzyRuleAntecedent *r31 = new FuzzyRuleAntecedent(); r31->joinWithAND(coklatPekat, sangatKental);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r31, THEN_TIDAK));

  FuzzyRuleAntecedent *r32a = new FuzzyRuleAntecedent(); r32a->joinWithAND(sangatKeruh, sangatKental);
  FuzzyRuleAntecedent *r32 = new FuzzyRuleAntecedent(); r32->joinWithAND(r32a, coklat);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r32, THEN_TIDAK));

  FuzzyRuleAntecedent *r33 = new FuzzyRuleAntecedent(); r33->joinWithAND(sangatKeruh, coklatPekat);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r33, THEN_TIDAK));

  FuzzyRuleAntecedent *r34 = new FuzzyRuleAntecedent(); r34->joinWithAND(sangatKental, coklatPekat);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r34, THEN_TIDAK));

  FuzzyRuleAntecedent *r35 = new FuzzyRuleAntecedent(); r35->joinWithAND(sangatKeruh, kuningCerah);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r35, THEN_LAYAK));

  FuzzyRuleAntecedent *r36 = new FuzzyRuleAntecedent(); r36->joinWithAND(sangatKeruh, kuningKecoklatan);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r36, THEN_LAYAK));

  FuzzyRuleAntecedent *r37 = new FuzzyRuleAntecedent(); r37->joinWithAND(sangatKental, kuningCerah);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r37, THEN_LAYAK));

  FuzzyRuleAntecedent *r38 = new FuzzyRuleAntecedent(); r38->joinWithAND(sangatKental, kuningKecoklatan);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r38, THEN_LAYAK));

  FuzzyRuleAntecedent *r39 = new FuzzyRuleAntecedent(); r39->joinWithAND(keruh, kuningCerah);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r39, THEN_LAYAK));

  FuzzyRuleAntecedent *r40 = new FuzzyRuleAntecedent(); r40->joinWithAND(keruh, kuningKecoklatan);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r40, THEN_LAYAK));
  
  Serial.println("[eFLL] Fuzzy Logic 40 Rules Berhasil Diinisialisasi.");
}

// ============================================================================
// INTERRUPT & PROTO FUNCTIONS
// ============================================================================
void IRAM_ATTR zeroCrossISR() {
  if (!motorDimmerEnable) return; 
  int d = currentDelay;
  
  if (d < 500) d = 500;
  if (d > 9000) d = 9000;
  DELAY_US(d);
  
  REG_WRITE(GPIO_OUT_W1TS_REG, (1UL << TRIAC_PIN));
  DELAY_US(TRIAC_PULSE_US);
  REG_WRITE(GPIO_OUT_W1TC_REG, (1UL << TRIAC_PIN));
  }

void dimmerControl() {
}

void setupWiFi();
void connectMQTT();
void mqttCallback(char* topic, byte* payload, unsigned int length);
void readRS485();
void sendControlToSlaves(bool status);
void hitungFuzzyLogic();
void publishTelemetry();
void postToLaravel();

// ============================================================================
// SETUP
// ============================================================================
void setup() { 
  WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0); 
  Serial.begin(115200);
  pinMode(pinSwitch, INPUT_PULLUP);
  Serial2.begin(9600, SERIAL_8N1, RXD2, TXD2); 
  Serial2.setTimeout(100);
  pinMode(RS485_DIR, OUTPUT);
  digitalWrite(RS485_DIR, LOW); 

  pinMode(RELAY_OPEN, OUTPUT); pinMode(RELAY_CLOSE, OUTPUT);
  pinMode(RELAY_PUMP1, OUTPUT); pinMode(RELAY_PUMP2, OUTPUT); pinMode(RELAY_PUMP3, OUTPUT);
  pinMode(RELAY_HEATER1, OUTPUT); pinMode(RELAY_HEATER2, OUTPUT);
  pinMode(RELAY_MOTOR, OUTPUT); pinMode(TRIAC_PIN, OUTPUT);
  pinMode(ZC_PIN, INPUT); pinMode(SWITCH_PIN, INPUT_PULLUP);

  // OFF Semua Aktuator (RELAY ACTIVE LOW -> HIGH = OFF)
  digitalWrite(RELAY_OPEN, HIGH); digitalWrite(RELAY_CLOSE, HIGH);
  digitalWrite(RELAY_PUMP1, HIGH); digitalWrite(RELAY_PUMP2, HIGH); digitalWrite(RELAY_PUMP3, HIGH);
  digitalWrite(RELAY_HEATER1, HIGH); digitalWrite(RELAY_HEATER2, HIGH);
  digitalWrite(RELAY_MOTOR, HIGH); digitalWrite(TRIAC_PIN, LOW); motorDimmerEnable = false;

  attachInterrupt(digitalPinToInterrupt(ZC_PIN), zeroCrossISR, RISING);
  
  Serial.println("OLIVIA READY (MASTER ESP32)");

  setupWiFi();
  setupFuzzy(); 

  espClient.setInsecure(); 
  client.setServer(mqtt_server, mqtt_port);
  client.setBufferSize(1024);
  client.setCallback(mqttCallback);
}

// ============================================================================
// LOOP
// ============================================================================
void loop() {
  unsigned long now = millis();

  // 1. KONEKTIVITAS
  if (WiFi.status() != WL_CONNECTED) {
    if (now - lastWifiCheck > 5000) { setupWiFi(); lastWifiCheck = now; }
  } else if (!client.connected()) {
    if (now - lastMqttRetry > 5000) { connectMQTT(); lastMqttRetry = now; }
  } else { client.loop(); }

  // 2. SCHEDULER POLLING RS485
  if (now - lastPollTime >= pollInterval) {
    lastPollTime = now;
    uint8_t targetSlave = (pollStage == 0) ? 1 : 2;
    while (Serial2.available()) Serial2.read();

    digitalWrite(RS485_DIR, HIGH);
    delay(3); 

    if (pollStage == 0) {
        Serial.println("========================");
        Serial.println("TX -> REQ:S1");
        Serial2.print("REQ:S1\n");
        Serial2.flush();
        pollStage = 1;
    } else {
        Serial.println("========================");
        Serial.println("TX -> REQ:S2");
        Serial2.print("REQ:S2\n");
        Serial2.flush();
        pollStage = 0;
    }

    delay(20);
    digitalWrite(RS485_DIR, LOW);
    delay(3);
    while (Serial2.available()) Serial2.read();

    lastSlaveReceived = 0;
    unsigned long startWait = millis();
    while (millis() - startWait < 1000) { 
        if (Serial2.available()) {
            readRS485();
            if (lastSlaveReceived == targetSlave) break;
        }
        delay(1);
    }
    if (lastSlaveReceived == 0) {
        Serial.printf("[MASTER] Timeout menunggu balasan Slave %d\n", targetSlave);
    }
}

  // 3. SWITCH SYSTEM FISIK
  bool currentSwitchState = digitalRead(SWITCH_PIN);
  if (currentSwitchState != lastSwitchState) {
    delay(50); 
    if (digitalRead(SWITCH_PIN) == currentSwitchState) {
      if (currentSwitchState == LOW) {
        Serial.println("SYSTEM ON (VIA PHYSICAL SWITCH)");
        timer = now; heaterTimer = now;
        state = START; 
        system_on = true;
        sendControlToSlaves(true);
      } else {
        Serial.println("SYSTEM OFF (VIA PHYSICAL SWITCH)");
        state = FINISH; process_step = 0; 
      }
      lastSwitchState = currentSwitchState;
    }
  }

  // 4. DIMMER KONTROL
  // dimmerControl();

  // 5. STATE MACHINE LOGIC
  switch(state) {
    case START:
      heaterTimer = now; state = HEATER1_RUN; current_step = "0"; process_step = 1;
      Serial.println("HEATER 1 START");
      break;

    case HEATER1_RUN:
      process_step = 1;
      if(suhu_arang >= SET_POINT) { 
        digitalWrite(RELAY_HEATER1, HIGH); Serial.println("HEATER 1 OFF");
        timer = now; state = FILTER_DELAY;
        break;
      }
      if(!heaterStatus) {
        if(now - heaterTimer >= HEATER_OFF_TIME) {
          heaterStatus = true; heaterTimer = now; current_step = "1";
          digitalWrite(RELAY_HEATER1, LOW); Serial.println("HEATER 1 ON");
        }
      } else {
        if(now - heaterTimer >= HEATER_ON_TIME) {
          heaterStatus = false; heaterTimer = now;
          digitalWrite(RELAY_HEATER1, HIGH);
        }
      }
      break;

    case FILTER_DELAY:
      process_step = 1;
      if(now - timer >= HEATER1_DELAY) { timer = now; state = VALVE_OPEN; }
      break;

    case VALVE_OPEN:
      process_step = 1;
      digitalWrite(RELAY_OPEN, LOW);
      if(now - timer >= VALVE_OPEN_TIME) { digitalWrite(RELAY_OPEN, HIGH); timer = now; state = VALVE_WAIT; }
      break;

    case VALVE_WAIT:
      process_step = 1;
      if(now - timer >= VALVE_WAIT_TIME) { digitalWrite(RELAY_CLOSE, LOW); timer = now; state = VALVE_CLOSE; }
      break;

    case VALVE_CLOSE:
      process_step = 1;
      if(now - timer >= VALVE_CLOSE_TIME) { digitalWrite(RELAY_CLOSE, HIGH); timer = now; state = DELAY_PUMP1; }
      break;

    case DELAY_PUMP1:
      process_step = 1;
      if(now - timer >= DELAY_TIME) { digitalWrite(RELAY_PUMP1, LOW); Serial.println("PUMP 1 ON"); timer = now; state = PUMP1_RUN; }
      break;

    case PUMP1_RUN:
      process_step = 1;
      if(now - timer >= PUMP1_TIME) { digitalWrite(RELAY_PUMP1, HIGH); Serial.println("PUMP 1 OFF"); timer = now; state = DELAY_HEATER2; }
      break;

    case DELAY_HEATER2:
      process_step = 2;
      if(now - timer >= DELAY_TIME) { heaterTimer = now; state = HEATER2_RUN; Serial.println("HEATER 2 START"); }
      break;

    case HEATER2_RUN:
      process_step = 2;
      if(suhu_bleaching >= SET_POINT) {
        digitalWrite(RELAY_HEATER2, HIGH); Serial.println("HEATER 2 OFF"); 
        currentDelay = 2000;
        digitalWrite(TRIAC_PIN, LOW); 
        digitalWrite(RELAY_MOTOR, LOW); 
        motorDimmerEnable = true;
        
        Serial.println("MOTOR ON");
        timer = now; state = MOTOR_RUN;
        break;
      }
      if(!heaterStatus) {
        if(now - heaterTimer >= HEATER_OFF_TIME) {
          heaterStatus = true; heaterTimer = now; digitalWrite(RELAY_HEATER2, LOW); Serial.println("HEATER 2 ON");
        }
      } else {
        if(now - heaterTimer >= HEATER_ON_TIME) {
          heaterStatus = false; heaterTimer = now; digitalWrite(RELAY_HEATER2, HIGH);
        }
      }
      break;

    case MOTOR_RUN:
      process_step = 2;
      if(now - timer >= MOTOR_TIME) { motorDimmerEnable = false; digitalWrite(TRIAC_PIN, LOW); digitalWrite(RELAY_MOTOR, HIGH); Serial.println("MOTOR OFF"); timer = now; state = FILTER_BLEACHING; }
      break;

    case FILTER_BLEACHING:
      process_step = 2;
      if(now - timer >= BLEACHING_TIME) { Serial.println("BLEACHING SELESAI"); timer = now; state = DELAY_PUMP2; }
      break;

    case DELAY_PUMP2:
      process_step = 2;
      if(now - timer >= DELAY_TIME) { digitalWrite(RELAY_PUMP2, LOW); Serial.println("PUMP 2 ON"); timer = now; state = PUMP2_RUN; }
      break;

    case PUMP2_RUN:
      process_step = 2;
      // Setelah PUMP 2 selesai, state berpindah ke DELAY_PUMP3 dengan timer normal
      if(now - timer >= PUMP2_TIME) { 
        digitalWrite(RELAY_PUMP2, HIGH); 
        Serial.println("PUMP 2 OFF"); 
        timer = now; 
        state = DELAY_PUMP3; 
      }
      break;

    case DELAY_PUMP3:
      process_step = 3;
      if(now - timer >= DELAY_FUZZY_TIME) { 
        digitalWrite(RELAY_PUMP3, LOW); 
        current_step = "VALIDASI QUALITY"; 
        Serial.println("PUMP 3 ON"); 
        timer = now; 
        state = PUMP3_RUN; 
      }
      break;

    case PUMP3_RUN:
      process_step = 3;
      // PUMP 3 berjalan murni berdasarkan PUMP3_TIME tanpa interupsi fail-safe
      if(now - timer >= PUMP3_TIME) { 
        digitalWrite(RELAY_PUMP3, HIGH); 
        Serial.println("PUMP 3 OFF"); 
        process_step = 4;
        state = FINISH; 
      }
      break;

    case FINISH:
      motorDimmerEnable = false; digitalWrite(TRIAC_PIN, LOW);
      digitalWrite(RELAY_OPEN, HIGH); digitalWrite(RELAY_CLOSE, HIGH);
      digitalWrite(RELAY_PUMP1, HIGH); digitalWrite(RELAY_PUMP2, HIGH); digitalWrite(RELAY_PUMP3, HIGH);
      digitalWrite(RELAY_HEATER1, HIGH); digitalWrite(RELAY_HEATER2, HIGH);
      digitalWrite(RELAY_MOTOR, HIGH); digitalWrite(TRIAC_PIN, LOW);
      system_on = false; current_step = "STANDBY";
      sendControlToSlaves(false);
      break;
  }

  // 6. PUBLISH DATA & EVALUASI FUZZY
if (now - lastPublishTime >= publishInterval) {
    lastPublishTime = now;
    
    hitungFuzzyLogic(); // Proses logika fuzzy
    
    if (WiFi.status() == WL_CONNECTED) {
      // 1. Kirim data ke Database Laravel
      postToLaravel();
      
      // 2. Kirim data ke Aplikasi Flutter (MQTT)
      if (client.connected()) {
        Serial.println("\n[MQTT] Mencoba mem-publish data ke HiveMQ...");
        publishTelemetry();
        Serial.println("[MQTT] Publish selesai!");
      } else {
        Serial.println("\n[MQTT] Gagal publish: Koneksi ke HiveMQ terputus.");
      }
    } else {
      Serial.println("\n[WIFI] Gagal publish: WiFi tidak terhubung.");
    }
  }
}

// ============================================================================
// KOMUNIKASI & ALGORITMA FUZZY EVALUATION
// ============================================================================
void setupWiFi() {
  WiFi.begin(ssid, password);
  int counter = 0;
  while (WiFi.status() != WL_CONNECTED && counter < 10) { delay(500); counter++; }
}

void connectMQTT() {
  if (client.connect(mqtt_client_id, mqtt_user, mqtt_pass)) { client.subscribe(topic_sub_control); }
}

void mqttCallback(char* topic, byte* payload, unsigned int length) {
  String msg = "";
  for (int i = 0; i < length; i++) msg += (char)payload[i];
  
  if (String(topic) == topic_sub_control) {
    if (msg.indexOf("\"system_on\":true") != -1 || msg == "1") {
      if (!system_on && state == FINISH) {
        system_on = true; state = START; timer = millis(); heaterTimer = millis(); sendControlToSlaves(true);
      }
    } else if (msg.indexOf("\"system_on\":false") != -1 || msg == "0") {
      system_on = false; state = FINISH; process_step = 0;
    }
  }
}

void sendControlToSlaves(bool status) {
  digitalWrite(RS485_DIR, HIGH); delayMicroseconds(50);
  Serial2.println(status ? "CTRL:1" : "CTRL:0");
  Serial2.flush(); delayMicroseconds(200); digitalWrite(RS485_DIR, LOW);
}

void readRS485() {

    while (Serial2.available()) {

        char c = Serial2.read();

        // Abaikan CR
        if (c == '\r')
            continue;

        // Belum akhir paket
        if (c != '\n') {
            rs485Buffer += c;
            continue;
        }

        // ==========================================
        // Paket lengkap diterima
        // ==========================================
        String line = rs485Buffer;
        rs485Buffer = "";

        line.trim();

        if (line.length() == 0)
            continue;

        Serial.print("[RAW RS485] ");
        Serial.println(line);

        // ========================================================
        // SLAVE 1
        // ========================================================
        if (line.startsWith("S1:")) {
            int jsonStart = line.indexOf('{');
            if (jsonStart == -1) {
                Serial.println("[ERROR] Format S1 salah");
                continue;
            }
            String jsonStr = line.substring(jsonStart);
            StaticJsonDocument<256> doc;
            DeserializationError error = deserializeJson(doc, jsonStr);
            if (error) {
                Serial.print("[ERROR] JSON S1 : ");
                Serial.println(error.c_str());
                continue;
            }
            suhu_arang     = doc["suhu_arang"]     | suhu_arang;
            volume_arang   = doc["volume_arang"]   | volume_arang;
            suhu_bleaching = doc["suhu_bleaching"] | suhu_bleaching;
            lastSlaveReceived = 1;
            Serial.printf(
                "[MASTER RX S1] Suhu Arang: %.1f C | Volume: %.2f L | Bleaching: %.1f C\n",
                suhu_arang,
                volume_arang,
                suhu_bleaching
            );
        }
        // ========================================================
        // SLAVE 2
        // ========================================================
        else if (line.startsWith("S2:")) {
            int jsonStart = line.indexOf('{');
            if (jsonStart == -1) {
                Serial.println("[ERROR] Format S2 salah");
                continue;
            }
            String jsonStr = line.substring(jsonStart);
            StaticJsonDocument<384> doc;
            DeserializationError error = deserializeJson(doc, jsonStr);
            if (error) {
                Serial.print("[ERROR] JSON S2 : ");
                Serial.println(error.c_str());
                continue;
            }
            volume_validasi = doc["volume_validasi"] | volume_validasi;
            turbidity       = doc["turbidity"]       | turbidity;
            viscosity       = doc["viscosity"]       | viscosity;
            redValue        = doc["r"]               | redValue;
            greenValue      = doc["g"]               | greenValue;
            blueValue       = doc["b"]               | blueValue;

            lastSlaveReceived = 2;

            Serial.printf(
                "[MASTER RX S2] Volume: %.2f L | Turbidity: %.1f NTU | Viscosity: %.1f cP | RGB: %d,%d,%d\n",
                volume_validasi,
                turbidity,
                viscosity,
                redValue,
                greenValue,
                blueValue
            );
        }
        // ========================================================
        // DATA TIDAK DIKENAL
        // ========================================================
        else {
            Serial.print("[WARNING] Unknown Packet : ");
            Serial.println(line);
        }
    }
}

// === ✅ FUNGSI UTAMA DIBAWAH TETAP DIPERTAHANKAN TANPA LOGIKA INTERUPSI FAIL-SAFE ===
void hitungFuzzyLogic() {
  // Input real-time ke eFLL Library
  fuzzy->setInput(1, turbidity);
  fuzzy->setInput(2, viscosity);
  fuzzy->setInput(3, redValue); 

  // Kalkulasi Algoritma Fuzzifikasi & Inferensi eFLL
  fuzzy->fuzzify();

  // Defuzzifikasi untuk mendapat nilai tegas Kelayakan (0 - 100%)
  kelayakan = fuzzy->defuzzify(1);

  // Penentuan Status String untuk UI Flutter dan DB Laravel
  if (kelayakan >= 85.0) status_layak = "SANGAT LAYAK";
  else if (kelayakan >= 70.0) status_layak = "LAYAK";
  else if (kelayakan >= 35.0) status_layak = "KURANG LAYAK";
  else status_layak = "TIDAK LAYAK";

  // Cetak Log hasil ke Serial Monitor untuk keperluan debugging internal
  Serial.printf("[FUZZY LOGIC] Kelayakan: %.2f%% | Status: %s\n", kelayakan, status_layak.c_str());
}

// === Fungsi Stubs Telemetry & Laravel (Sesuaikan dengan isi program Anda sebelumnya) ===
void publishTelemetry() {
  StaticJsonDocument<1024> doc;
  doc["system_on"] = system_on; doc["current_step"] = current_step; doc["process_step"] = process_step;
  doc["suhu_arang"] = suhu_arang; doc["volume_arang"] = volume_arang;
  doc["suhu_bleaching"] = suhu_bleaching;
  
  doc["valve"] = (digitalRead(RELAY_OPEN) == LOW || digitalRead(RELAY_CLOSE) == LOW);
  doc["p1"] = (digitalRead(RELAY_PUMP1) == LOW); 
  doc["p2"] = (digitalRead(RELAY_PUMP2) == LOW); 
  doc["p3"] = (digitalRead(RELAY_PUMP3) == LOW);
  
  // =========================================================
  // ✅ PERBAIKAN HEATER (1 Relay untuk 2 Heater)
  // =========================================================
  bool relayHeater1_ON = (digitalRead(RELAY_HEATER1) == LOW);
  bool relayHeater2_ON = (digitalRead(RELAY_HEATER2) == LOW);
  
  doc["h1"] = relayHeater1_ON; 
  doc["h2"] = relayHeater1_ON; // h2 ikut h1
  doc["h3"] = relayHeater2_ON; 
  doc["h4"] = relayHeater2_ON; // h4 ikut h3
  // =========================================================
  int delayCopy = currentDelay;
  doc["speed"] = (digitalRead(RELAY_MOTOR) == LOW) ? map(delayCopy, 8000, 1000, 0, 500) : 0;
  
  doc["volume_validasi"] = volume_validasi;
  doc["turbidity"] = turbidity; doc["viscosity"] = viscosity;
  doc["r"] = redValue; doc["g"] = greenValue; doc["b"] = blueValue;
  doc["kelayakan"] = kelayakan; doc["status_layak"] = status_layak;
  

  // 1. Simpan ke buffer
  char buf[1024]; 
  serializeJson(doc, buf); 

  // 2. Tampilkan di Serial Monitor agar kita tahu bentuk aslinya
  Serial.print("[DATA MQTT DIKIRIM]: ");
  Serial.println(buf);

  // 3. Tembak langsung ke topik
  client.publish("olivia/OLIVIA-MASTER/telemetry", buf);
}


void postToLaravel() {
  HTTPClient http;
  http.begin(laravel_base_url + "iot/master/store");
  http.addHeader("Content-Type", "application/json");

  StaticJsonDocument<1024> doc;
  doc["system_on"] = system_on ? 1 : 0;
  doc["suhu_arang"] = suhu_arang; doc["volume_arang"] = volume_arang;
  doc["suhu_bleaching"] = suhu_bleaching;
  
  doc["valve"] = (digitalRead(RELAY_OPEN) == LOW) ? 1 : 0;
  doc["p1"] = (digitalRead(RELAY_PUMP1) == LOW) ? 1 : 0; 
  doc["p2"] = (digitalRead(RELAY_PUMP2) == LOW) ? 1 : 0; 
  doc["p3"] = (digitalRead(RELAY_PUMP3) == LOW) ? 1 : 0;
  
  // =========================================================
  // ✅ PERBAIKAN HEATER UNTUK DATABASE LARAVEL
  // =========================================================
  int heater1_val = (digitalRead(RELAY_HEATER1) == LOW) ? 1 : 0;
  int heater2_val = (digitalRead(RELAY_HEATER2) == LOW) ? 1 : 0;
  
  doc["h1"] = heater1_val; 
  doc["h2"] = heater1_val; 
  doc["h3"] = heater2_val; 
  doc["h4"] = heater2_val;
  // =========================================================
  
  int delayCopy = currentDelay;
  doc["speed"] = (digitalRead(RELAY_MOTOR) == LOW) ? map(delayCopy, 8000, 1000, 0, 500) : 0; 
  doc["volume_validasi"] = volume_validasi;
  doc["turbidity"] = turbidity; doc["viscosity"] = viscosity;
  doc["r"] = redValue; doc["g"] = greenValue; doc["b"] = blueValue;
  doc["kelayakan"] = kelayakan; doc["status_layak"] = status_layak;

  String payload; serializeJson(doc, payload);
  http.POST(payload); http.end();
}