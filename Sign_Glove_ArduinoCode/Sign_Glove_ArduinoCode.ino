#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <SoftwareSerial.h> // For Bluetooth communication

// MPU6050
Adafruit_MPU6050 mpu;

// Flex Sensors
const int flexSensorPins[] = {A0, A1, A2, A3, A6};
const int numFlexSensors = 5;
int flexSensorValues[numFlexSensors];

// Bluetooth Module
SoftwareSerial bluetooth(10, 11); // RX, TX

// Variables for MPU6050 readings
float accelValues[3]; // X, Y, Z for accelerometer
float gyroValues[3];  // X, Y, Z for gyroscope

// Function for initializing MPU6050
void initializeMPU6050() {
    if (!mpu.begin()) {
        Serial.println("Failed to find MPU6050 chip");
        while (1) delay(10);
    }

    mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
    mpu.setGyroRange(MPU6050_RANGE_500_DEG);
    mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
    delay(100);
}

// Function to read MPU6050 data
void readMPU6050() {
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);

    // Store accelerometer and gyroscope data
    accelValues[0] = a.acceleration.x;
    accelValues[1] = a.acceleration.y;
    accelValues[2] = a.acceleration.z;

    gyroValues[0] = g.gyro.x;
    gyroValues[1] = g.gyro.y;
    gyroValues[2] = g.gyro.z;
}

// Function to send data via Bluetooth
void sendData() {
    String data = "Flex:";
    for (int i = 0; i < numFlexSensors; i++) {
        data += flexSensorValues[i];
        if (i < numFlexSensors - 1) data += ",";
    }

    data += "|Accel:";
    for (int i = 0; i < 3; i++) {
        data += String(accelValues[i], 2);
        if (i < 2) data += ",";
    }

    data += "|Gyro:";
    for (int i = 0; i < 3; i++) {
        data += String(gyroValues[i], 2);
        if (i < 2) data += ",";
    }

    // Print and send data
    Serial.println(data);
    bluetooth.println(data);
}

void setup() {
    // Initialize Serial and Bluetooth
    Serial.begin(9600);
    bluetooth.begin(9600);
    
    // Initialize MPU6050
    Serial.println("Initializing MPU6050...");
    initializeMPU6050();

    // Initialize flex sensor pins
    for (int i = 0; i < numFlexSensors; i++) {
        pinMode(flexSensorPins[i], INPUT);
    }

    Serial.println("Initialization Complete!");
}

void loop() {
    // Read flex sensor values
    for (int i = 0; i < numFlexSensors; i++) {
        flexSensorValues[i] = analogRead(flexSensorPins[i]);
    }

    // Read MPU6050 data
    readMPU6050();

    // Send data via Bluetooth
    sendData();

    // Add a delay to control data transmission frequency
    delay(1000); // 100ms delay 1000 ms for app
}
