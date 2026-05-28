// ========================================
// PERBAIKAN ESP32 MASTER - KODE YANG PERLU DIUBAH
// ========================================

// ❌ SEBELUM (MISMATCH)
const char* topic_publish     = "olivia/purifikasi/telemetry";  // Flutter expect: olivia/telemetry
const char* topic_sub_control = "olivia/control";              // Flutter publish: olivia/control/request

// ✅ SESUDAH (FIXED)
const char* topic_publish     = "olivia/telemetry";            // Sama dengan flutter subscribe
const char* topic_sub_control = "olivia/control";              // Atau bisa "olivia/control/request"


// ========================================
// FIX #2: TAMBAH BLEACHING SPEED DI JSON
// ========================================

// ❌ SEBELUM (MISSING SPEED)
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
// ← TIDAK ADA SPEED!

// ✅ SESUDAH (ADDED SPEED)
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
bleaching["speed"] = 0;  // ← TAMBAH INI (atau sesuai logika motor)


// ========================================
// FIX #3: VISKOSITAS KONVERSI
// ========================================

// CURRENT (POSSIBLY WRONG):
float f_khz = doc2["freq"];
slave2_viscosity = f_khz * 1000.0;  
// Jika freq = 0.123 kHz → viscosity = 123 (tapi fuzzy expect 33000-40000!)

// OPSI 1: Naikkan multiplier (RECOMMENDED)
float f_khz = doc2["freq"];
slave2_viscosity = f_khz * 100000.0;  // Jika freq = 0.123 kHz → viscosity = 12300
// Tapi still perlu sesuaikan dengan fuzzy range actual dari sensor

// OPSI 2: Redefine Fuzzy Input Range (jika freq selalu 0-1000 range)
// Ganti di setupFuzzy():
FuzzyInput *viskositas = new FuzzyInput(2);
FuzzySet *encer        = new FuzzySet(300, 350, 400, 400);      // Dari 36500 → 300
FuzzySet *sedang       = new FuzzySet(280, 290, 290, 300);
FuzzySet *kental       = new FuzzySet(240, 280, 280, 320);
FuzzySet *sangatKental = new FuzzySet(0, 0, 200, 240);


// ========================================
// FIX #4: TAMBAH TINGGI DI SLAVE 2 (OPTIONAL)
// ========================================

// DI SLAVE 2 LOOP:
String payload = "{\"volume\":" + String(volumeLiter, 2) +
                 ",\"tinggi\":" + String(tinggiMinyak, 2) +  // ← TAMBAH OPTIONAL
                 ",\"ntu\":" + String(ntu, 2) +
                 ",\"r\":" + String(redValue) +
                 ",\"g\":" + String(greenValue) +
                 ",\"b\":" + String(blueValue) +
                 ",\"freq\":" + String(freq555 / 1000.0, 3) + "}";

// DI MASTER PARSING:
if (rawData.startsWith("S2:")) {
  StaticJsonDocument<512> doc2;
  DeserializationError error = deserializeJson(doc2, rawData.substring(3));
  if (!error) {
    if(doc2.containsKey("tinggi")) slave2_tinggi = doc2["tinggi"];  // Already ada
    // ... rest of parsing
  }
}


// ========================================
// FIX #5: IMPROVEMENT - FUZZY WARNA (OPTIONAL)
// ========================================

// CURRENT: Hanya pakai R value
fuzzy->setInput(3, slave2_r);  // 0-255

// BETTER: Hitung Hue dari RGB atau weighted average
// Hitung Hue dari HSV:
float getRGBHue(int r, int g, int b) {
  float rf = r / 255.0;
  float gf = g / 255.0;
  float bf = b / 255.0;
  
  float cmax = max({rf, gf, bf});
  float cmin = min({rf, gf, bf});
  float delta = cmax - cmin;
  
  float hue = 0;
  if (delta == 0)
    hue = 0;
  else if (cmax == rf)
    hue = fmod((gf - bf) / delta, 6) * 60;
  else if (cmax == gf)
    hue = ((bf - rf) / delta + 2) * 60;
  else
    hue = ((rf - gf) / delta + 4) * 60;
  
  if (hue < 0) hue += 360;
  return hue;  // 0-360 degrees
}

// Dalam loop SLAVE 2 processing:
float hue = getRGBHue(redValue, greenValue, blueValue);
fuzzy->setInput(3, hue);  // Pakai hue instead of R

// Redefine fuzzy warna (0-360 range):
FuzzySet *kuningCerah      = new FuzzySet(40, 50, 60, 70);       // Yellow
FuzzySet *kuningKecoklatan = new FuzzySet(25, 35, 45, 55);       // Orange-yellow
FuzzySet *coklat           = new FuzzySet(10, 20, 30, 40);       // Orange-brown
FuzzySet *coklatPekat      = new FuzzySet(0, 5, 15, 25);         // Dark brown

// ========================================
// TESTING CHECKLIST
// ========================================
// [ ] Ubah topic_publish ke "olivia/telemetry"
// [ ] Ubah atau samakan topic_sub_control
// [ ] Tambah bleaching["speed"] di JSON
// [ ] Fix viscosity conversion (cek actual range dari sensor)
// [ ] Build & upload ke Master ESP32
// [ ] Verify di Flutter: Dashboard data muncul realtime
// [ ] Test: Tekan tombol ON/OFF di Flutter → sistem respond
// [ ] Selesai! ✅
