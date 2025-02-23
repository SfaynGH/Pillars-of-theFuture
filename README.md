# Gorah Farming 🌾

## 📖 Overview
Gorah Farming is a comprehensive smart agriculture solution designed for greenhouse management, integrating IoT devices, AI-powered decision-making, and a user-friendly mobile application built with **Flutter**. The system automates irrigation, monitors plant health, and supports greenhouse owners with real-time data and AI-driven insights, all while promoting sustainability through solar energy.

The application includes:
- **Automated Irrigation Control** based on real-time sensor data.
- **Plant Disease Detection** using AI models.
- **AI-Powered Chatbot** for farming tips, greenhouse control, and scheduling (powered by Gemini).
- **Trading Platform** for fruits, fertilizers, and agricultural tools.
- **Fire Detection Alerts** to notify users in case of greenhouse fire risks.

All system operations are powered by solar panels, aligning with eco-friendly farming practices and the principles of Industry 5.0, which emphasize human-technology collaboration.

---

## 🖼️ Prototype Image
<div align="center">
<img src=prototype.jpg"/>

  <br/>
  
</div>

---

## 📊 Prototype Conception
The system architecture includes:
- **ESP32** central node for a greenhouse.
- **Sensors** for temperature, humidity, soil moisture, and gas detection.
- **motor** simulating the smart valve
<div align="center">
<img src=conception.jpg"/>

  <br/>
  
</div>
---

## 📲 User Interface Screenshots
<div align="center">
<img src=UI.png"/>

  <br/>
  
</div>

---

## 🌐 General Architecture

<div align="center">
<img src=architecture.png"/>

  <br/>
  
</div>
---

## ⚙️ How to Run the Project
1. **Clone the Repository:**
   ```bash
   git clone https://github.com/yourusername/gorah-farming.git
   ```

2. **Set Up the Environment:**
   - Install dependencies for the Flutter app and ML models.
   - Configure Firebase and Cloudinary keys.

3. **Run the Flutter Mobile Application:**
   ```bash
   cd mobile-app
   flutter pub get
   flutter run
   ```

4. **Launch AI Models:**
   - Open the Jupyter notebooks inside `/models`.
   - Run each cell to load and test the plant disease detection and irrigation decision models.

5. **Connect IoT Devices:**
   - Configure ESP32 boards to send data to Firebase.
   - Ensure Raspberry Pi runs the local AI models and manages sensor data.



