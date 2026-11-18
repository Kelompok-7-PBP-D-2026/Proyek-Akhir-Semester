# MBG Mobile — Proyek Akhir Semester

Aplikasi mobile (Flutter) dari **MBG**, situs web penyaluran makanan siap saji surplus
untuk program Makan Bergizi Gratis yang dibangun di Proyek Tengah Semester. Aplikasi
ini mengambil dan mengirim data melalui web service Django REST Framework yang
dibangun di situs web Django PTS, dan data tetap tersimpan di situs web tersebut.

## Anggota Kelompok

| Nama | NPM |
| --- | --- |
| Joshua Imanuel Setiawan | 2506656854 |
| Kireina Naura Alifa | 2506590006 |
| Immanuel Marvin Pandjaitan | 2506623881 |
| Fikri Okto Setiadi | 2506621655 |
| Rindu Maharani Nadhirah | 2506587131 |

## Deskripsi Aplikasi

**MBG Mobile** adalah versi mobile dari situs web MBG. Aplikasi ini menyambungkan
donor makanan (panitia acara, kantin, katering) dengan penerima (mahasiswa) agar
makanan surplus tidak terbuang: donor mengunggah donasi makanan, penerima mengklaim
dan mereservasi, pengambilan dilakukan di titik venue kampus, dan admin memantau
dampaknya lewat laporan bulanan yang siap dipakai untuk SDG 2 dan SDG 12.

## Modul dan Pembagian Kerja

Pembagian modul sama dengan Proyek Tengah Semester — setiap anggota melanjutkan
modul yang sama, dalam bentuk halaman-halaman Flutter yang terhubung ke endpoint
Django REST Framework milik modul tersebut.

| No | Modul | Deskripsi | PIC |
| --- | --- | --- | --- |
| 1 | Profil Pengguna | Halaman profil donor (panitia acara, kantin, katering) dan profil penerima (mahasiswa): melengkapi data saat registrasi, melihat dan mengedit profil sendiri, serta filter daftar donor berdasarkan jenis donor. | Fikri Okto Setiadi |
| 2 | Donasi Makanan | Halaman daftar dan detail item makanan surplus: donor dapat membuat, melihat, mengedit, dan menghapus donasi, serta memfilter donasi berdasarkan lokasi dan waktu. | Rindu Maharani Nadhirah |
| 3 | Klaim dan Reservasi | Halaman klaim yang berelasi dengan item makanan dan penerima: penerima membuat klaim, melihat status klaim, dan membatalkannya; donor dapat menghapus klaim yang tidak diambil. | Kireina Naura Alifa |
| 4 | Venue dan Lokasi | Halaman titik pengambilan berisi nama gedung, fakultas, koordinat, dan deskripsi akses: admin dan donor mengelola venue, dengan peta dan jarak ke lokasi pengguna. | Immanuel Marvin Pandjaitan |
| 5 | Laporan Dampak | Halaman laporan berisi periode, total makanan tersalurkan, dan jumlah donor serta penerima yang terlibat: admin membuat laporan dari agregasi data klaim, mengedit, menghapus, dan mengunduhnya. | Joshua Imanuel Setiawan |

## Peran / Aktor Pengguna

| Aktor | Deskripsi |
| --- | --- |
| Donor | Panitia acara, kantin, atau katering yang mengunggah dan mengelola donasi makanan serta venue pengambilan. |
| Penerima | Mahasiswa yang melihat daftar donasi, membuat klaim/reservasi, dan melengkapi profilnya. |
| Admin | Pengelola sistem yang memantau donasi dan klaim, mengelola venue, serta menyusun laporan dampak. |

## Alur Integrasi Aplikasi Mobile dan Situs Web (PWS)

1. Situs web Django dari Proyek Tengah Semester tetap menjadi sumber data tunggal —
   database (PostgreSQL di PWS) dan seluruh logika bisnis berada di sana.
2. Di dalam proyek Django tersebut, ditambahkan **Django REST Framework**:
   setiap modul memiliki **serializer** dan **view/viewset** sendiri, lalu di-daftarkan
   sebagai endpoint di `urls.py`.
3. Aplikasi Flutter memanggil endpoint tersebut secara **asinkron** (`http` /
   `async-await`) melalui HTTP request ke web service di PWS.
4. Respons JSON dari web service di-*decode* ke model Dart, lalu ditampilkan di
   halaman-halaman Flutter; aksi pengguna (buat/edit/hapus) dikirim kembali sebagai
   request `POST`/`PUT`/`DELETE` ke endpoint yang sama.
5. Autentikasi sesi/cookie dari situs web dipakai juga oleh aplikasi, sehingga hak
   akses per aktor (donor/penerima/admin) konsisten antara web dan mobile.

## Desain Figma

https://www.figma.com/design/pe8sMgak0HFt6aJ8HDKDDI/Untitled?node-id=0-1&t=gtbSmqaM9Dz7bjkh-1

## Tautan APK

_Tautan menyusul setelah Checkpoint 1 (Release GitHub + Bitrise)._

## Scoping Aplikasi Mobile

Scope aplikasi mobile mengikuti scope modul Proyek Tengah Semester, disesuaikan
ke bentuk mobile: setiap modul PTS menjadi halaman-halaman Flutter yang terhubung
ke endpoint Django REST Framework milik modul tersebut. Data tetap tersimpan di
situs web Django PTS; aplikasi mobile tidak menyimpan data secara mandiri.

Yang berada dalam scope CP1 per modul:

1. **Profil Pengguna (Fikri)** — halaman profil donor dan profil penerima
   (melengkapi data saat registrasi, melihat dan mengedit profil sendiri),
   serta filter daftar donor berdasarkan jenis donor.
2. **Donasi Makanan (Rindu)** — halaman daftar dan detail item makanan surplus;
   donor membuat, melihat, mengedit, dan menghapus donasi, serta memfilter
   donasi berdasarkan lokasi dan waktu.
3. **Klaim dan Reservasi (Kireina)** — halaman klaim yang berelasi dengan item
   makanan dan penerima; penerima membuat klaim, melihat status klaim, dan
   membatalkannya; donor dapat menghapus klaim yang tidak diambil.
4. **Venue dan Lokasi (Marvin)** — halaman titik pengambilan (nama gedung,
   fakultas, koordinat, deskripsi akses); admin dan donor mengelola venue,
   dengan peta dan jarak ke lokasi pengguna.
5. **Laporan Dampak (Joshua)** — halaman laporan berisi periode, total makanan
   tersalurkan, dan jumlah donor serta penerima yang terlibat; admin membuat,
   mengedit, menghapus, dan mengunduh laporan.

Di luar scope (tetap jalan di situs web, tidak diduplikasi ke mobile): panel
admin Django, ekspor PDF/CSV laporan, dan integrasi OpenStreetMap versi web.

## Web Service (Django REST Framework)

Endpoint berada di proyek Django Proyek Tengah Semester (database PostgreSQL di
PWS). Autentikasi memakai sesi web yang sama (cookie-based); endpoint tulis
menuntut login, endpoint baca klaim/laporan/profil hanya untuk pengguna terkait.

| Modul | Endpoint | Akses |
| --- | --- | --- |
| Profil Pengguna | `GET /api/profil-donor/`, `GET /api/profil-penerima/` | login (read-only) |
| Donasi Makanan | `GET/POST/PUT/DELETE /donasi/api/donasi/` | baca publik; tulis wajib login, donor di-set dari sesi |
| Klaim dan Reservasi | `GET/POST/PUT/DELETE /klaim/api/claim/` | login; tiap pengguna hanya melihat klaim yang dibuat/ditujukan kepadanya |
| Venue dan Lokasi | `GET/POST/PUT/DELETE /venue/api/venue/` | baca publik; tulis wajib login |
| Laporan Dampak | `GET /laporan/api/laporan/` | login (read-only) |

Pembatalan klaim, verifikasi kode ambil, dan ekspor laporan masih memakai
halaman web sampai halaman mobile-nya selesai.
