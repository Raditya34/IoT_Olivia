#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <Fuzzy.h>
#include <HTTPClient.h> 

// ==========================================
// 1. KONFIGURASI WIFI, MQTT CLOUD & API
// ==========================================
const char* ssid     = "Raditya";     
const char* password = "akusukakmu";  

const char* mqtt_server    = "a24e7a00b6d943c2be69eafa2c60943f.s1.eu.hivemq.cloud";
const int mqtt_port        = 8883; 
const char* mqtt_user      = "Olivia_IoT";
const char* mqtt_pass      = "Olivia12345";
const char* mqtt_client_id = "esp32_master_olivia";

// ✅ FIX #1: UBAH TOPIC PUBLISH DARI olivia/purifikasi/telemetry → olivia/telemetry
const char* topic_publish     = "olivia/telemetry"; 
// Subscribe wildcard to accept both plain control and request/response subtopics
const char* topic_sub_control = "olivia/control/#";

const String laravel_base_url = "https://iotolivia-production.up.railway.app/api/";

WiFiClientSecure espClient;
PubSubClient client(espClient);

unsigned long lastMqttRetry = 0;
unsigned long lastWifiCheck = 0;
unsigned long lastPublishTime = 0;
const unsigned long publishInterval = 3000; 

// ==========================================
// 2. KONFIGURASI RS485 & DATA REGISTER
// ==========================================
#define RXD2 16
#define TXD2 17
#define RS485_DIR 4
HardwareSerial RS485(2);

// Penampung Data Global dari Slave
float slave1_suhu_arang = 0.0;
float slave1_suhu_bleaching = 0.0;
float slave1_volume_arang = 0.0;
float slave1_tinggi_arang = 0.0;

float slave2_tinggi = 0.0;
float slave2_volume = 0.0;
float slave2_turbidity = 0.0;
float slave2_viscosity = 0.0;
int slave2_r = 0, slave2_g = 0, slave2_b = 0;

float hasil_kelayakan = 0.0;
String status_kelayakan = "TIDAK LAYAK";

bool system_on = false;

// Variabel Status Output Aktuator
bool st_valve = false, st_p1 = false, st_p2 = false, st_p3 = false;
bool st_h1 = false, st_h2 = false, st_h3 = false, st_h4 = false;

// ==========================================
// 3. INISIALISASI FUZZY LOGIC ENGINE (30 RULES FINAL)
// ==========================================
Fuzzy *fuzzy = new Fuzzy();

void setupFuzzy() {
  // =====================================================
  // INPUT 1 : TURBIDITY
  // =====================================================
  FuzzyInput *turbidity = new FuzzyInput(1);

  FuzzySet *sangatJernih = new FuzzySet(0, 0, 100, 136);
  FuzzySet *jernih       = new FuzzySet(135, 165, 165, 205);
  FuzzySet *keruh        = new FuzzySet(204, 245, 245, 286);
  FuzzySet *sangatKeruh  = new FuzzySet(285, 305, 500, 500);

  turbidity->addFuzzySet(sangatJernih);
  turbidity->addFuzzySet(jernih);
  turbidity->addFuzzySet(keruh);
  turbidity->addFuzzySet(sangatKeruh);
  fuzzy->addFuzzyInput(turbidity);

  // =====================================================
  // INPUT 2 : VISKOSITAS
  // =====================================================
  FuzzyInput *viskositas = new FuzzyInput(2);

  FuzzySet *encer        = new FuzzySet(36500, 37000, 40000, 40000);
  FuzzySet *sedang       = new FuzzySet(36000, 36450, 36450, 36550);
  FuzzySet *kental       = new FuzzySet(34000, 35100, 35100, 36000);
  FuzzySet *sangatKental = new FuzzySet(0, 0, 33000, 34000);

  viskositas->addFuzzySet(encer);
  viskositas->addFuzzySet(sedang);
  viskositas->addFuzzySet(kental);
  viskositas->addFuzzySet(sangatKental);
  fuzzy->addFuzzyInput(viskositas);

  // =====================================================
  // INPUT 3 : WARNA
  // =====================================================
  FuzzyInput *warna = new FuzzyInput(3);

  FuzzySet *kuningCerah      = new FuzzySet(214, 231, 255, 255);
  FuzzySet *kuningKecoklatan = new FuzzySet(170, 195, 195, 215);
  FuzzySet *coklat           = new FuzzySet(100, 135, 135, 171);
  FuzzySet *coklatPekat      = new FuzzySet(0, 0, 90, 101);

  warna->addFuzzySet(kuningCerah);
  warna->addFuzzySet(kuningKecoklatan);
  warna->addFuzzySet(coklat);
  warna->addFuzzySet(coklatPekat);
  fuzzy->addFuzzyInput(warna);

  // =====================================================
  // OUTPUT : KUALITAS (KELAYAKAN)
  // =====================================================
  FuzzyOutput *kualitas = new FuzzyOutput(1);

  FuzzySet *tidakLayak  = new FuzzySet(0, 0, 25, 41);
  FuzzySet *kurangLayak = new FuzzySet(35, 55, 55, 75);
  FuzzySet *layak       = new FuzzySet(70, 80, 80, 90);
  FuzzySet *sangatLayak = new FuzzySet(85, 95, 100, 100);

  kualitas->addFuzzySet(tidakLayak);
  kualitas->addFuzzySet(kurangLayak);
  kualitas->addFuzzySet(layak);
  kualitas->addFuzzySet(sangatLayak);
  fuzzy->addFuzzyOutput(kualitas);

  // =====================================================
  // CONSEQUENT
  // =====================================================
  FuzzyRuleConsequent *THEN_TIDAK = new FuzzyRuleConsequent();
  THEN_TIDAK->addOutput(tidakLayak);

  FuzzyRuleConsequent *THEN_KURANG = new FuzzyRuleConsequent();
  THEN_KURANG->addOutput(kurangLayak);

  FuzzyRuleConsequent *THEN_LAYAK = new FuzzyRuleConsequent();
  THEN_LAYAK->addOutput(layak);

  FuzzyRuleConsequent *THEN_SANGAT = new FuzzyRuleConsequent();
  THEN_SANGAT->addOutput(sangatLayak);

  // =====================================================
  // 30 RULES
  // =====================================================
  int nomorRule = 1;

  // RULE 1
  FuzzyRuleAntecedent *r1a = new FuzzyRuleAntecedent();
  r1a->joinWithAND(sangatJernih, encer);
  FuzzyRuleAntecedent *r1 = new FuzzyRuleAntecedent();
  r1->joinWithAND(r1a, kuningCerah);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r1, THEN_SANGAT));

  // RULE 2
  FuzzyRuleAntecedent *r2a = new FuzzyRuleAntecedent();
  r2a->joinWithAND(jernih, sedang);
  FuzzyRuleAntecedent *r2 = new FuzzyRuleAntecedent();
  r2->joinWithAND(r2a, kuningKecoklatan);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r2, THEN_LAYAK));

  // RULE 3
  FuzzyRuleAntecedent *r3a = new FuzzyRuleAntecedent();
  r3a->joinWithAND(keruh, kental);
  FuzzyRuleAntecedent *r3 = new FuzzyRuleAntecedent();
  r3->joinWithAND(r3a, coklat);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r3, THEN_KURANG));

  // RULE 4
  FuzzyRuleAntecedent *r4a = new FuzzyRuleAntecedent();
  r4a->joinWithAND(sangatKeruh, sangatKental);
  FuzzyRuleAntecedent *r4 = new FuzzyRuleAntecedent();
  r4->joinWithAND(r4a, coklatPekat);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r4, THEN_TIDAK));

  // RULE 5
  FuzzyRuleAntecedent *r5 = new FuzzyRuleAntecedent();
  r5->joinSingle(sangatKeruh);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r5, THEN_TIDAK));

  // RULE 6
  FuzzyRuleAntecedent *r6 = new FuzzyRuleAntecedent();
  r6->joinSingle(sangatKental);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r6, THEN_TIDAK));

  // RULE 7
  FuzzyRuleAntecedent *r7 = new FuzzyRuleAntecedent();
  r7->joinSingle(coklatPekat);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r7, THEN_TIDAK));

  // RULE 8
  FuzzyRuleAntecedent *r8 = new FuzzyRuleAntecedent();
  r8->joinWithAND(jernih, coklat);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r8, THEN_KURANG));

  // RULE 9
  FuzzyRuleAntecedent *r9 = new FuzzyRuleAntecedent();
  r9->joinWithAND(keruh, kuningKecoklatan);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r9, THEN_KURANG));

  // RULE 10
  FuzzyRuleAntecedent *r10 = new FuzzyRuleAntecedent();
  r10->joinWithAND(kental, kuningCerah);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r10, THEN_KURANG));

  // RULE 11
  FuzzyRuleAntecedent *r11 = new FuzzyRuleAntecedent();
  r11->joinWithAND(sangatJernih, sedang);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r11, THEN_LAYAK));

  // RULE 12
  FuzzyRuleAntecedent *r12 = new FuzzyRuleAntecedent();
  r12->joinWithAND(jernih, encer);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r12, THEN_LAYAK));

  // RULE 13
  FuzzyRuleAntecedent *r13 = new FuzzyRuleAntecedent();
  r13->joinWithAND(kuningKecoklatan, kental);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r13, THEN_KURANG));

  // RULE 14
  FuzzyRuleAntecedent *r14 = new FuzzyRuleAntecedent();
  r14->joinWithAND(keruh, sedang);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r14, THEN_KURANG));

  // RULE 15
  FuzzyRuleAntecedent *r15 = new FuzzyRuleAntecedent();
  r15->joinWithAND(sangatKeruh, coklat);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r15, THEN_TIDAK));

  // RULE 16
  FuzzyRuleAntecedent *r16a = new FuzzyRuleAntecedent();
  r16a->joinWithAND(jernih, kuningCerah);
  FuzzyRuleAntecedent *r16 = new FuzzyRuleAntecedent();
  r16->joinWithAND(r16a, sedang);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r16, THEN_LAYAK));

  // RULE 17
  FuzzyRuleAntecedent *r17a = new FuzzyRuleAntecedent();
  r17a->joinWithAND(keruh, coklat);
  FuzzyRuleAntecedent *r17 = new FuzzyRuleAntecedent();
  r17->joinWithAND(r17a, sedang);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r17, THEN_KURANG));

  // RULE 18
  FuzzyRuleAntecedent *r18 = new FuzzyRuleAntecedent();
  r18->joinWithAND(sangatJernih, kuningKecoklatan);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r18, THEN_LAYAK));

  // RULE 19
  FuzzyRuleAntecedent *r19 = new FuzzyRuleAntecedent();
  r19->joinWithAND(jernih, kuningCerah);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r19, THEN_SANGAT));

  // RULE 20
  FuzzyRuleAntecedent *r20 = new FuzzyRuleAntecedent();
  r20->joinWithAND(sangatJernih, encer);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r20, THEN_SANGAT));

  // RULE 21
  FuzzyRuleAntecedent *r21 = new FuzzyRuleAntecedent();
  r21->joinWithAND(sangatJernih, kuningCerah);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r21, THEN_SANGAT));

  // RULE 22
  FuzzyRuleAntecedent *r22 = new FuzzyRuleAntecedent();
  r22->joinWithAND(encer, kuningCerah);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r22, THEN_SANGAT));

  // RULE 23
  FuzzyRuleAntecedent *r23 = new FuzzyRuleAntecedent();
  r23->joinWithAND(jernih, sedang);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r23, THEN_LAYAK));

  // RULE 24
  FuzzyRuleAntecedent *r24 = new FuzzyRuleAntecedent();
  r24->joinWithAND(sedang, kuningKecoklatan);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r24, THEN_LAYAK));

  // RULE 25
  FuzzyRuleAntecedent *r25 = new FuzzyRuleAntecedent();
  r25->joinWithAND(jernih, kuningKecoklatan);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r25, THEN_LAYAK));

  // RULE 26
  FuzzyRuleAntecedent *r26 = new FuzzyRuleAntecedent();
  r26->joinWithAND(keruh, kental);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r26, THEN_KURANG));

  // RULE 27
  FuzzyRuleAntecedent *r27 = new FuzzyRuleAntecedent();
  r27->joinWithAND(keruh, coklat);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r27, THEN_KURANG));

  // RULE 28
  FuzzyRuleAntecedent *r28 = new FuzzyRuleAntecedent();
  r28->joinWithAND(kental, coklat);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r28, THEN_KURANG));

  // RULE 29
  FuzzyRuleAntecedent *r29 = new FuzzyRuleAntecedent();
  r29->joinWithAND(sangatKeruh, sangatKental);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r29, THEN_TIDAK));

  // RULE 30
  FuzzyRuleAntecedent *r30 = new FuzzyRuleAntecedent();
  r30->joinWithAND(sangatKeruh, coklatPekat);
  fuzzy->addFuzzyRule(new FuzzyRule(nomorRule++, r30, THEN_TIDAK));
}

// ==========================================
// 4. CALLBACK MQTT INCOMING
// ==========================================
void callback(char* topic, byte* payload, unsigned int length) {
  String message = "";
  for (unsigned int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  Serial.print("\n[MQTT RECEIVED] Command masuk: "); Serial.println(message);
  
  StaticJsonDocument<256> doc;
  DeserializationError error = deserializeJson(doc, message);
  if (!error) {
    if (doc.containsKey("system_on")) {
      system_on = doc["system_on"].as<bool>();
      Serial.print("Sistem diubah ke -> "); Serial.println(system_on ? "ON" : "OFF");
    }
  }
}

// ==========================================
// 5. MANAGEMENT KONEKSI JARINGAN
// ==========================================
void maintainNetwork() {
  unsigned long now = millis();
  if (WiFi.status() != WL_CONNECTED) {
    if (now - lastWifiCheck > 5000) {
      lastWifiCheck = now;
      Serial.println("[WIFI] Terputus! Mencoba menghubungkan kembali...");
      WiFi.begin(ssid, password);
    }
    return;
  }
  if (!client.connected()) {
    if (now - lastMqttRetry > 5000) {
      lastMqttRetry = now;
      Serial.print("[MQTT] Menghubungkan ke HiveMQ Cloud...");
      if (client.connect(mqtt_client_id, mqtt_user, mqtt_pass)) {
        Serial.println(" BERHASIL TERHUBUNG!");
        client.subscribe(topic_sub_control);
      } else {
        Serial.print(" GAGAL, RC="); Serial.println(client.state());
      }
    }
  }
}

void sendToLaravelAPI(String endpoint, String jsonPayload) {
  if (WiFi.status() == WL_CONNECTED) {
    WiFiClientSecure clientHTTP; 
    clientHTTP.setInsecure(); 
    HTTPClient http;
    http.setTimeout(4000); 
    http.begin(clientHTTP, laravel_base_url + endpoint); 
    http.addHeader("Content-Type", "application/json");
    int httpResponseCode = http.POST(jsonPayload);
    Serial.printf("[HTTP API] Post to %s | Code response: %d\n", endpoint.c_str(), httpResponseCode);
    http.end();
  }
}

// ==========================================
// 6. SETUP UTAMA
// ==========================================
void setup() {
  Serial.begin(115200);
  
  pinMode(RS485_DIR, OUTPUT);
  digitalWrite(RS485_DIR, LOW); 
  RS485.begin(9600, SERIAL_8N1, RXD2, TXD2);
  RS485.setTimeout(50); 

  setupFuzzy(); 
  Serial.println("MASTER FUZZY READY DENGAN 30 RULES");
  
  WiFi.begin(ssid, password);
  espClient.setInsecure(); 
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
  client.setBufferSize(1024); 
}

// ==========================================
// 7. LOOP UTAMA
// ==========================================
void loop() {
  maintainNetwork();
  if (client.connected()) {
    client.loop();
  }

  // PENGOLAHAN SERIAL DATA MASUK DARI JALUR RS485
  if (RS485.available() > 0) {
    String rawData = RS485.readStringUntil('\n');
    rawData.trim();
    
    // PEMBACAAN DATA SLAVE 1
    if (rawData.startsWith("S1:")) {
      StaticJsonDocument<512> doc1;
      DeserializationError error = deserializeJson(doc1, rawData.substring(3));
      if (!error) {
        slave1_suhu_arang = doc1["suhu_arang"];
        slave1_suhu_bleaching = doc1["suhu_bleaching"];
        if(doc1.containsKey("tinggi")) slave1_tinggi_arang = doc1["tinggi"];
        slave1_volume_arang = doc1["volume_arang"];
      }
    } 
    // PEMBACAAN DATA SLAVE 2 & PROSES FUZZY
    else if (rawData.startsWith("S2:")) {
      StaticJsonDocument<512> doc2;
      DeserializationError error = deserializeJson(doc2, rawData.substring(3));
      if (!error) {
        if(doc2.containsKey("tinggi")) slave2_tinggi = doc2["tinggi"];
        slave2_volume = doc2["volume"];
        slave2_turbidity = doc2["ntu"];
        
        float f_khz = doc2["freq"];
        // ✅ FIX #3: UBAH VISCOSITY CONVERSION DARI f_khz * 1000.0 → f_khz * 100000.0
        slave2_viscosity = f_khz * 100000.0; // Visko sesuai instruksi (fixed multiplier)
        
        slave2_r = doc2["r"];
        slave2_g = doc2["g"];
        slave2_b = doc2["b"];
        
        // ==========================================
        // PROSES INFERENSI FUZZY
        // ==========================================
        fuzzy->setInput(1, slave2_turbidity);
        fuzzy->setInput(2, slave2_viscosity);
        fuzzy->setInput(3, slave2_r); // input warna pakai R sesuai code Anda

        fuzzy->fuzzify();
        hasil_kelayakan = fuzzy->defuzzify(1);

        Serial.println("\n=========== DATA SENSOR ===========");
        Serial.print("TINGGI         : "); Serial.print(slave2_tinggi); Serial.println(" cm");
        Serial.print("VOLUME         : "); Serial.print(slave2_volume); Serial.println(" L");
        Serial.print("NTU            : "); Serial.println(slave2_turbidity);
        Serial.print("VISKOSITAS     : "); Serial.println(slave2_viscosity);
        Serial.print("WARNA R        : "); Serial.println(slave2_r);
        
        Serial.println("=========== HASIL FUZZY ===========");
        Serial.print("KELAYAKAN      : "); Serial.println(hasil_kelayakan);

        if (hasil_kelayakan <= 41) {
          status_kelayakan = "TIDAK LAYAK";
        } else if (hasil_kelayakan <= 75) {
          status_kelayakan = "KURANG LAYAK";
        } else if (hasil_kelayakan <= 90) {
          status_kelayakan = "LAYAK";
        } else {
          status_kelayakan = "SANGAT LAYAK";
        }
        
        Serial.print("STATUS         : "); Serial.println(status_kelayakan);
        Serial.println("===================================");
        
        // Logika Aktuator (Aman Saat System Off)
        if (system_on) {
          st_valve = true;
          st_p1 = true; st_p2 = true; st_p3 = false;
          st_h1 = (slave1_suhu_bleaching < 80.0);
          st_h2 = st_h1; st_h3 = st_h1; st_h4 = st_h1;
        } else {
          st_valve = false; st_p1 = false; st_p2 = false; st_p3 = false;
          st_h1 = false; st_h2 = false; st_h3 = false; st_h4 = false;
        }
      }
    }
  }

  // SIKLUS PUBLISH DATA
  unsigned long currentMillis = millis();
  if (currentMillis - lastPublishTime >= publishInterval) {
    lastPublishTime = currentMillis;

    StaticJsonDocument<1024> docOut;
    docOut["system_on"] = system_on;

    JsonObject arang = docOut.createNestedObject("arang");
    arang["suhu_arang"] = slave1_suhu_arang;
    arang["volume_arang"] = slave1_volume_arang;

    JsonObject bleaching = docOut.createNestedObject("bleaching");
    bleaching["suhu_bleaching"] = slave1_suhu_bleaching;
    bleaching["valve"] = st_valve;
    bleaching["p1"] = st_p1; 
    bleaching["p2"] = st_p2; 
    bleaching["p3"] = st_p3;
    bleaching["h1"] = st_h1; 
    bleaching["h2"] = st_h2; 
    bleaching["h3"] = st_h3; 
    bleaching["h4"] = st_h4;
    // ✅ FIX #2: TAMBAH BLEACHING SPEED
    bleaching["speed"] = 0; // atau nilai sesuai logika motor Anda

    JsonObject validasi = docOut.createNestedObject("validasi");
    validasi["volume_validasi"] = slave2_volume;
    validasi["turbidity"] = slave2_turbidity;
    validasi["viscosity"] = slave2_viscosity;
    validasi["r"] = slave2_r; 
    validasi["g"] = slave2_g; 
    validasi["b"] = slave2_b;
    validasi["kelayakan"] = hasil_kelayakan; // Data Fuzzy Kelayakan dikirim ke MQTT / Laravel
    validasi["status_layak"] = status_kelayakan;

    if (client.connected()) {
      String mqttPayload;
      serializeJson(docOut, mqttPayload);
      client.publish(topic_publish, mqttPayload.c_str());
    }

    String outArang, outBleaching, outValidasi;
    serializeJson(arang, outArang);
    serializeJson(bleaching, outBleaching);
    serializeJson(validasi, outValidasi);

    sendToLaravelAPI("iot/esp1/store", outArang); 
    sendToLaravelAPI("iot/esp2/store", outBleaching); 
    sendToLaravelAPI("iot/esp3/store", outValidasi); 
  }
}
