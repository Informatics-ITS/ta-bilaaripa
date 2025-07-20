# 🏁 Tugas Akhir (TA) - Final Project

**Nama Mahasiswa**: Salsabila Fatma Aripa<br>
**NRP**: 5025211057 <br>
**Judul TA**: Penerapan _Convolutional Neural Network_ untuk Klasifikasi Cacar Monyet menggunakan YOLOv11 <br>
**Dosen Pembimbing**: Agus Budi Raharjo, S.Kom., M.Kom., Ph.D. <br> 
**Dosen Ko-pembimbing**: Dr. Dwi Sunaryono, S.Kom., M.Kom.

---
## 📑 Daftar Isi

- [📺 Demo Aplikasi](#-demo-aplikasi)
- [🛠 Panduan Instalasi & Menjalankan Software](#-panduan-instalasi--menjalankan-software)
  - [Prasyarat](#prasyarat)
  - [Langkah-langkah](#langkah-langkah)
- [📚 Dokumentasi Tambahan](#-dokumentasi-tambahan)
  - [Dataset](#dataset)
  - [Diagram Arsitektur](#diagram-arsitektur)
  - [Poster](#poster)
- [⁉️ Pertanyaan?](#️-pertanyaan)

---

## 📺 Demo Aplikasi  

[![Demo Aplikasi](https://github.com/user-attachments/assets/9a7c016d-4eda-4d8e-9145-880ae44196e8)](https://www.youtube.com/watch?v=o4uWv5VgGdQ)
*Klik gambar di atas untuk menonton demo*

---

## 🛠 Panduan Instalasi & Menjalankan Software  

### Prasyarat  
- Tahap Persiapan:
  - Python 3.8+ (untuk model dan backend)
  - Flutter SDK 3.7.2+
  - Dart SDK
  - Android Studio / VS Code
  - Git
  - Firebase Account (untuk mobile app)

---

### Langkah-langkah  
1. **Clone Repository**  
   ```bash
   git clone https://github.com/Informatics-ITS/ta-bilaaripa.git
   ```
2. **Setup Model Klasifikasi**
   ```bash
   cd model-classification
   ```
   - Jika anda memakai Google Colab dapat mengunggah project pada layanan tersebut
   - Dependensi Model
     ```bash
     pip install ultralytics
     pip install torch torchvision
     pip install scikit-learn
     pip install numpy
     pip install tqdm
     pip install pillow
     pip install seaborn
     pip install matplotlib
     ```
---
  
3. **Setup Backend**
   - cd fastapi-backend dan jalankan requerements.txt
   ```bash
   cd fastapi-backend
   pip install -r requirements.txt
   ```
   - Anda dapat menyipakan model pada `/app/model`
   - Masuk ke /app lalu jenjalakan program dengan : 
   ```bash
   cd app
   uvicorn app.main:app --host 0.0.0.0 --port 8000
   ```
   - Lalu buka browser dan kunjungi : `http://127.0.0.1:8000/docs` (port dapat menggunakan ipconfig)
   - Anda dapat melakukan test endpoint upload gambar untuk klasifikasi

---
  
4. **Setup Mobile App**
   ```bash
   cd mobile-app
   ```
   - Instal Dependencies
   ```bash
   flutter pub get
   ```
   - Konfigurasi Firebase
     - Buat project Firebase baru
     - Download `google-services.json` (untuk android)
     - Tempatkan file configurasi pada tempat yang tepat `android/app/google-services.json`
   - Konfigurasi App Icon
   ```bash
   flutter pub run flutter_launcher_icons:main
   ```
   - Sesuaikan Backend URL
     - Buka /lib/screens/scan/scan_screen.dart
     - Sesuaikan BASE_URL dengan alamat server FastAPI Anda
     ```bash
     static const String _baseUrl = 'http://your-server-ip:8000'; 
     ```
   - Build and Run
   ```bash
   flutter pub get
   flutter run
   flutter build apk --release
   ```

---
   
5. Catatan
   - Jalankan backend terlebih dahulu
   - Pastikan model sudah ter-load dengan benar
   - Test API endpoint sebelum menjalankan mobile app
   - Gunakan emulator/device yang terhubung internet yang Sama dengan komputer yang menjalankan backend

---

## 📚 Dokumentasi Tambahan
### Dataset

Berikut adalah daftar dataset yang digunakan dalam penelitian ini:

1. **The Monkeypox Skin Images Dataset (MSID)**  
   [🔗 https://data.mendeley.com/datasets/r9bfpnvyxr/6](https://data.mendeley.com/datasets/r9bfpnvyxr/6)

2. **The Monkeypox Skin Lesion Dataset (MSLD)**  
   [🔗 https://www.kaggle.com/datasets/joydippaul/mpox-skin-lesion-dataset-version-20-msld-v20](https://www.kaggle.com/datasets/joydippaul/mpox-skin-lesion-dataset-version-20-msld-v20)

3. **The Mpox Close Skin Image Dataset (MCSI)**  
   [🔗 https://zenodo.org/records/8360076](https://zenodo.org/records/8360076)

### Diagram Arsitektur
[![Diagram Arsitektur](https://github.com/user-attachments/assets/301d40c7-1224-4ffd-b3c4-fed3ba68e693)](https://github.com/user-attachments/assets/301d40c7-1224-4ffd-b3c4-fed3ba68e693)

### Poster
[![Poster Tugas Akhir](https://github.com/user-attachments/assets/d6f88096-65ad-4134-aaee-b02f0854a9d1)](https://github.com/user-attachments/assets/d6f88096-65ad-4134-aaee-b02f0854a9d1)


---

## ⁉️ Pertanyaan?

Hubungi:
- Penulis: [5025211057@student.its.ac.id]
- Pembimbing Utama: [agus.budi@its.ac.id]
