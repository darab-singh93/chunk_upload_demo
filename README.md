# 📦 Flutter Chunked File Upload (with Pause/Resume & Queue Support)

A full-stack demo app where files can be uploaded from a **Flutter app** to a **Node.js server** using **chunked and resumable upload**.

---

## ✅ Features

- 🔁 Upload files in chunks (1MB per chunk)
- 🛑 Pause / ▶️ Resume upload manually
- 🔁 Automatically resume upload after hot restart
- 📥 Upload multiple files in a queue
- 🔢 Real-time upload progress per file
- ✅ Resumable even after connection drop or app kill
- 📁 Backend stores files in `uploads/` folder

---

## 🧩 Tech Stack

- **Frontend:** Flutter
- **Backend:** Node.js (Express.js, fs-extra)
- **File Picker:** `file_picker`
- **HTTP Requests:** `http`
- **Persistence:** `shared_preferences`

💻 Node.js Backend Setup
1. Prerequisites
Node.js 16+

2. Create Backend Server
- cd backend
- npm init -y
- npm install express cors fs-extra

3. Create server.js

4. Run the Server
node server.js

✅ Files are saved in uploads/ directory


## 🧑‍💻 Author
Built with ❤️ by Darab Singh
