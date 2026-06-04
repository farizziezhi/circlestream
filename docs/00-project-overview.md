# CircleStream — Project Overview

## Tagline
**Real-Time, Raw, and Intimate Photo Stream.**

---

## What Is CircleStream?

CircleStream adalah aplikasi mobile **private photo sharing** yang dirancang khusus untuk kelompok kecil teman dekat.

Tidak ada follower. Tidak ada feed publik. Tidak ada algoritma. Hanya foto real-time yang dibagikan ke circle privat kamu.

---

## Core Principles

| Prinsip | Penjelasan |
|---|---|
| **Private by Default** | Semua konten hanya terlihat oleh member circle |
| **Camera First** | Foto langsung dari kamera, bukan galeri |
| **Real-Time** | Semua member melihat foto baru secara instan |
| **No Followers** | Tidak ada konsep following/follower |
| **No Public Feed** | Tidak ada konten publik |
| **No Comments** | Tidak ada komentar teks, hanya emoji reaction |
| **No Algorithms** | Feed kronologis murni, tanpa ranking |

---

## Problem Statement

Social media saat ini terlalu publik, terlalu berisik, dan terlalu penuh algoritma. Orang kehilangan tempat untuk berbagi momen sehari-hari secara jujur dengan teman dekat.

CircleStream hadir sebagai ruang privat yang terasa seperti grup chat foto — instan, personal, dan bebas dari tekanan sosial.

---

## Target Users

- Kelompok teman dekat (5–10 orang)
- Pasangan atau keluarga kecil
- Kelompok yang ingin berbagi momen secara spontan
- Orang yang lelah dengan social media publik

---

## Technology Stack Summary

| Layer | Technology |
|---|---|
| Frontend | Flutter |
| Backend API | Golang + Fiber |
| Database | Turso (SQLite edge) |
| Media Storage | Cloudflare R2 |
| Real-time | Ably |
| Cache / Counter | Upstash Redis |

---

## Key Differentiators

1. **Bukan social media** — tidak ada follower, like, atau komentar
2. **Circle privat** — maksimal 10 orang per circle
3. **Camera-first** — foto langsung dari kamera, bukan upload galeri
4. **Real-time** — semua event (post, reaction, join/leave) muncul instan
5. **Minimalis** — UI bersih tanpa clutter

---

## Project Status

MVP in development.

Read order untuk AI agents tersedia di `README.md` root project.
