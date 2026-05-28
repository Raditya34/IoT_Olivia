# 🚀 QUICK FIX UNTUK ESP32 MASTER

## 3 Changes CRITICAL yang harus dilakukan:

### 1️⃣ UBAH MQTT TOPIC PUBLISH (Line ~28)
```cpp
// BEFORE:
const char* topic_publish = "olivia/purifikasi/telemetry";

// AFTER:
const char* topic_publish = "olivia/telemetry";
```
**Why**: Flutter subscribe ke `olivia/telemetry`, bukan `olivia/purifikasi/telemetry`

---

### 2️⃣ TAMBAH BLEACHING SPEED DI JSON (Line ~308)
```cpp
// Cari bagian ini di loop utama, setelah buat JsonObject bleaching:
bleaching["h4"] = st_h4;
bleaching["speed"] = 0;  // ← TAMBAH BARIS INI
```
**Why**: Flutter menunggu field `speed`, tanpa ini akan default 0

---

### 3️⃣ FIX VISCOSITY CONVERSION (Line ~256)
```cpp
// BEFORE:
float f_khz = doc2["freq"];
slave2_viscosity = f_khz * 1000.0;

// AFTER (cek mana yang cocok dengan sensor):
// Option A: Kalau freq 0.xxx kHz dan fuzzy range masih 33000-40000
slave2_viscosity = f_khz * 100000.0;

// Option B: Atau ubah Fuzzy Input Range di setupFuzzy() dari 33000-40000 jadi 0-1000
```
**Why**: Fuzzy input range 33000-40000 tidak cocok dengan freq dalam kHz

---

## Setelah Edit:

1. **Build & Upload** ke ESP32 Master
   ```bash
   Arduino IDE → Tools → Upload
   ```

2. **Test di Flutter**
   - Tekan tombol di Dashboard
   - Lihat data real-time muncul atau tidak
   - Coba ON/OFF system

3. **Cek Serial Monitor** Master ESP32:
   - Harus ada log: `[MQTT] Connected and subscribed to topics!`
   - Harus ada: `[MQTT RECEIVED] Command masuk`
   - Data publish setiap 3 detik

---

## Common Issues Kalau Masih Bermasalah:

| Issue | Check |
|-------|-------|
| Dashboard kosong | MQTT topic cocok? Check di HiveMQ Cloud |
| ON/OFF tidak work | `topic_sub_control` cocok dengan Flutter publish |
| Data tidak update | WiFi/MQTT connected? Check Serial logs |
| Fuzzy hasil aneh | Viscosity range cocok dengan sensor actual |

