[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev/)
[![FastAPI](https://img.shields.io/badge/FastAPI-%2300C7B7.svg?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![ngrok](https://img.shields.io/badge/ngrok-%23800080.svg?style=for-the-badge&logo=ngrok&logoColor=white)](https://ngrok.com/)

# Overview

The Smart Glove is an innovative wearable device designed to translate sensor data into corresponding words or alphabets efficiently. This project showcases the integration of hardware and software to create a practical and efficient solution for sign language users to effectively communicate with non-signers.

# Machine Learning Model
https://github.com/Redgerd/Smart-Glove-Sign-Language-Predictor

## Features

- **Feature 1**: Tracks Finger movements in real time.

- **Feature 2**: Bluetooth connectivity for seamless integration with mobile apps.

- **Feature 3**: Long battery life with efficient power management.

- **Feature 4**: Lightweight and ergonomic design for all-day use.

- **Feature 5**: An in-app education module for quick access to frequently used alphabets.

# Technologies and Tools

## Hardware Components

1. Arduino Nano
2. Flex Sensors
3. GyroScope
4. JDY-SP-311 Bluetooth Module


## Software

### Programming Language:
Python, Dart.

### Frameworks/Libraries:
FastAPI, Arduino IDE, Android Studio.

### Mobile App Integration:
Flutter

# Installation

## Software Setup

### Clone the repository:

git clone https://github.com/hba777/sign_glove_application.git

### Install required dependencies:

pip install

### Upload the firmware to the microcontroller using Arduino IDE

Use arduino code given in repo

### Create and active the virtual environment:
 .venv\Scripts\Activate.ps1

### Run the server:

uvicorn main:app --host 0.0.0.0 --port 8000

Open the mobile app to connect to the glove.

### Run ngrok server:
Open cmd and type "ngrok http 8000":

### Replace URL in app
Replace URL in HomeScreen.dart with ngrok URL.

# Usage

1. Power on the glove by connecting it to your PC.

2. Pair the glove with your device via Bluetooth.

3. Open the companion app.

Start using the glove for sign language translations.
