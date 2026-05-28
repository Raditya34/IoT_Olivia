# 🔴 MISMATCH ANALYSIS: ESP32 Master ↔ Flutter App

## 1. ❌ MQTT TOPIC MISMATCH (CRITICAL)

### Master Publish:
```cpp
const char* topic_publish = "olivia/purifikasi/telemetry";
```

### Flutter Subscribe:
```dart
subscribe('olivia/telemetry');      // ← BERBEDA!
subscribe('olivia/system');
subscribe('olivia/control/response');
```

**PROBLEM**: Flutter menunggu data dari `olivia/telemetry` tapi Master kirim ke `olivia/purifikasi/telemetry`
- Dashboard akan kosong karena tidak menerima data apapun ❌

**FIX**: Ubah di Master atau Flutter (pilih 1):
- **Option A (RECOMMENDED)**: Master publish ke `olivia/telemetry` (lebih umum)
- **Option B**: Flutter subscribe ke `olivia/purifikasi/telemetry`

---

## 2. ❌ MQTT CONTROL TOPIC MISMATCH

### Master Subscribe:
```cpp
const char* topic_sub_control = "olivia/control";
client.subscribe(topic_sub_control);
```

### Flutter Publish:
```dart
_mqttService.publish('olivia/control/request', { ... });
```

**PROBLEM**: Master listen ke `olivia/control` tapi Flutter publish ke `olivia/control/request` ❌
- Perintah ON/OFF tidak akan sampai ke Master

**FIX**: Samakan topiknya ke `olivia/control/request` atau `olivia/control`

---

## 3. ❌ COMMAND FORMAT MISMATCH

### Master Expect:
```cpp
if (doc.containsKey("system_on")) {
  system_on = doc["system_on"].as<bool>();
}
```

### Flutter Send:
```dart
_mqttService.publish('olivia/control/request', {
  'command': 'system_toggle',    // ← Extra field
  'system_on': targetStatus,
  'timestamp': DateTime.now().toIso8601String(),  // ← Extra field
});
```

**PROBLEM**: Master hanya cek `system_on`, tapi Flutter juga kirim `command` dan `timestamp`
- Master bisa process tapi `command` field diabaikan (tidak critical)
- **Status**: Partial OK ⚠️

**FIX**: Master bisa maintain saja (backward compatible) atau Flutter hanya kirim `system_on`

---

## 4. ❌ MISSING BLEACHING SPEED IN JSON

### Flutter Expect:
```dart
bleachSpeed.value = bleaching['speed'] ?? 0;
```

### Master Send:
```cpp
JsonObject bleaching = docOut.createNestedObject("bleaching");
bleaching["suhu_bleaching"] = slave1_suhu_bleaching;
bleaching["valve"] = st_valve;
bleaching["p1"] = st_p1; 
// ... tapi TIDAK ada bleaching["speed"]
```

**PROBLEM**: Flutter menunggu `speed` tapi Master tidak kirimnya ❌
- UI akan selalu show `bleachSpeed = 0`

**FIX**: Tambahkan di Master:
```cpp
bleaching["speed"] = 0; // atau nilai sesuai logika
```

---

## 5. ⚠️ SLAVE DATA STRUCTURE

### Slave 1 Send:
```json
{"suhu_arang": X, "suhu_bleaching": Y, "tinggi": Z, "volume_arang": W}
```

### Slave 2 Send:
```json
{"volume": X, "ntu": Y, "r": Z, "g": W, "b": V, "freq": F}
```

### Master Parsing:
```cpp
if (rawData.startsWith("S1:")) {
  slave1_suhu_arang = doc1["suhu_arang"];
  slave1_suhu_bleaching = doc1["suhu_bleaching"];
  if(doc1.containsKey("tinggi")) slave1_tinggi_arang = doc1["tinggi"];
  slave1_volume_arang = doc1["volume_arang"];
}
// ✅ Cocok

if (rawData.startsWith("S2:")) {
  if(doc2.containsKey("tinggi")) slave2_tinggi = doc2["tinggi"];
  slave2_volume = doc2["volume"];
  slave2_turbidity = doc2["ntu"];
  // ✅ Cocok tapi perlu "tinggi"
  
  float f_khz = doc2["freq"];
  slave2_viscosity = f_khz * 1000.0;  // Konversi kHz → nilai untuk fuzzy
  // ⚠️ Perlu verify range yang dikirim Slave 2
}
```

**ISSUE**: Slave 2 tidak kirim `tinggi` 
- Master expect tapi tidak send di Slave 2 payload ⚠️

---

## 6. ⚠️ FUZZY VISCOSITY INPUT RANGE

### Master Fuzzy Input 2 (Viskositas):
```cpp
FuzzySet *encer        = new FuzzySet(36500, 37000, 40000, 40000);
FuzzySet *sedang       = new FuzzySet(36000, 36450, 36450, 36550);
FuzzySet *kental       = new FuzzySet(34000, 35100, 35100, 36000);
FuzzySet *sangatKental = new FuzzySet(0, 0, 33000, 34000);
```

### Master Set Viscosity:
```cpp
float f_khz = doc2["freq"];
slave2_viscosity = f_khz * 1000.0; // Konversi kHz → unit untuk fuzzy
fuzzy->setInput(2, slave2_viscosity);
```

**ISSUE**: 
- Range Fuzzy: 33000 - 40000 (untuk unit apa? viscosity dalam cSt seharusnya 30-100)
- Slave 2 kirim freq dalam kHz (0.xxx kHz)
- Multiply dengan 1000.0 baru jadi 0-999 (too small untuk fuzzy!)

**EXAMPLE**:
- Slave 2 kirim: `freq: 0.123` kHz
- Master convert: `0.123 * 1000 = 123`
- Fuzzy expect: 33000-40000
- **MISMATCH!** ❌

**FIX**: Perlu verify conversion:
```cpp
// Option 1: Multiply dengan lebih besar
slave2_viscosity = f_khz * 100000.0; // Jadi 12300

// Option 2: Atau Fuzzy range harus disesuaikan
// Fuzzy input range: 0-1000 (jika freq dalam kHz)
```

---

## 7. ⚠️ FUZZY WARNA INPUT (R VALUE ONLY)

### Master:
```cpp
fuzzy->setInput(3, slave2_r); // Hanya R component (0-255)
```

### Fuzzy Warna Range:
```cpp
FuzzySet *kuningCerah      = new FuzzySet(214, 231, 255, 255);  // R=214-255
FuzzySet *kuningKecoklatan = new FuzzySet(170, 195, 195, 215);  // R=170-215
FuzzySet *coklat           = new FuzzySet(100, 135, 135, 171);  // R=100-171
FuzzySet *coklatPekat      = new FuzzySet(0, 0, 90, 101);       // R=0-101
```

**ISSUE**: Fuzzy hanya pakai R value, tapi tidak combine dengan G dan B
- Seharusnya pakai kombinasi RGB atau H (Hue) dari HSV
- Dengan hanya R, accuracy color detection berkurang ⚠️

**BETTER**: Hitung HSV Hue atau pakai average RGB

---

## SUMMARY - PRIORITY FIXES

### 🔴 CRITICAL (Harus Fix):
1. **MQTT Topic Mismatch** → Flutter tidak terima data
   - Fix: Master publish ke `olivia/telemetry`
2. **Control Topic Mismatch** → Perintah tidak sampai
   - Fix: Master subscribe ke `olivia/control/request` atau `olivia/control`
3. **Viscosity Conversion** → Fuzzy dapat input salah
   - Fix: Adjust multiplier atau fuzzy range

### 🟡 MEDIUM (Segera):
4. **Missing Bleaching Speed** → Data tidak lengkap
   - Fix: Tambah `bleaching["speed"]` di Master
5. **Fuzzy Color Input** → Akurasi warna berkurang
   - Fix: Gunakan HSV atau weighted RGB

### 🟢 LOW (Optional):
6. **Slave 2 Tinggi** → Data tambahan
   - Fix: Add `tinggi` ke Slave 2 atau remove dari parsing

---

## RECOMMENDED CODE CHANGES

### MASTER FIX #1: Topic Names
```cpp
const char* topic_publish = "olivia/telemetry"; // ← CHANGE from olivia/purifikasi/telemetry
const char* topic_sub_control = "olivia/control"; // or olivia/control/request
```

### MASTER FIX #2: Add Bleaching Speed
```cpp
JsonObject bleaching = docOut.createNestedObject("bleaching");
bleaching["suhu_bleaching"] = slave1_suhu_bleaching;
bleaching["speed"] = 0; // ADD THIS LINE
```

### MASTER FIX #3: Viscosity Conversion
```cpp
// Before:
slave2_viscosity = f_khz * 1000.0;

// After (pilih satu):
slave2_viscosity = f_khz * 100000.0; // Untuk range 0-1000
// atau redefine Fuzzy range ke 0-1000 instead of 33000-40000
```

---

**Kesimpulan**: Ada 3 critical mismatch yang harus diperbaiki di Master ESP32 agar Flutter bisa terima data realtime dengan benar.
