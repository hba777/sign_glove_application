import serial
import joblib
import pandas as pd
import numpy as np

# Load the trained model
model = joblib.load("rf_model.pkl")

def read_serial_data(port, baud_rate):
    try:
        # Establish serial connection
        with serial.Serial(port, baud_rate, timeout=1) as ser:
            print(f"Connected to serial device on {port} at {baud_rate} baud.")
            data_list = []

            while True:
                try:
                    # Read a line of data from the serial port
                    raw_data = ser.readline().decode('utf-8').strip()

                    if raw_data:
                        print(f"Received data: {raw_data}")

                        # Check if the data contains "Flex:" (or any other identifier in your format)
                        if "Flex:" in raw_data:
                            try:
                                # Extract flex, accel, and gyro data
                                flex_data = raw_data.split('|')[0].replace('Flex:', '').split(',')
                                accel_data = raw_data.split('|')[1].replace('Accel:', '').split(',')
                                gyro_data = raw_data.split('|')[2].replace('Gyro:', '').split(',')

                                # Combine all sensor data
                                all_data = flex_data + accel_data + gyro_data

                                # Debug: Print the length of all_data and the raw data
                                print(f"Parsed data: {all_data}")
                                print(f"Number of values: {len(all_data)}")

                                # Convert the data to a list of floats
                                parsed_data = [float(x) for x in all_data]

                                # Ensure there are exactly 11 values (5 from flex, 3 from accel, 3 from gyro)
                                if len(parsed_data) == 11:
                                    # Create a DataFrame for prediction
                                    input_data = pd.DataFrame([parsed_data], columns=["Flex1", "Flex2", "Flex3", "Flex4", "Flex5", "AccelX", "AccelY", "AccelZ", "GyroX", "GyroY", "GyroZ"])

                                    # Make a prediction using the loaded model
                                    prediction = model.predict(input_data)
                                    print(f"Predicted label: {int(prediction[0])}")
                                else:
                                    print(f"Invalid data format: Incorrect number of values. Expected 11, got {len(parsed_data)}.")
                            except Exception as e:
                                print(f"Error parsing data: {e}")

                        else:
                            print("Invalid data format: Missing 'Flex:' identifier. Skipping.")

                except Exception as e:
                    print(f"Error while reading data: {e}")
                    break

    except serial.SerialException as e:
        print(f"Failed to connect to the serial device: {e}")

    except KeyboardInterrupt:
        print("Program interrupted by user.")

if __name__ == "__main__":
    # Specify the serial port and baud rate
    port = "COM4"  # Replace with your serial port (e.g., '/dev/ttyUSB0' for Linux)
    baud_rate = 9600  # Must match the baud rate of the serial device

    read_serial_data(port, baud_rate)
