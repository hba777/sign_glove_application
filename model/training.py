import serial
import csv
import time

# Set the serial port and baud rate to match Arduino's configuration
arduino_port = 'COM4'  # Change COMx to your Arduino port
baud_rate = 9600

# Open the serial connection
ser = serial.Serial(arduino_port, baud_rate)
time.sleep(2)  # Give time for the serial connection to initialize

# Ask user for label name (the name of the file or general description)
label_name = input("Enter a label name for the data (e.g., 'sensor_data'): ").strip()

# Ask user for labels for the sensors
labels = input("Enter custom labels for the sensors (e.g., 'FlexSensor1, FlexSensor2, FlexSensor3'): ").split(',')

# Open a CSV file for writing with the label name
csv_file = open(f'{label_name}.csv', mode='w', newline='')
csv_writer = csv.writer(csv_file)

# Write the header row based on the label name and sensor labels
csv_writer.writerow(['Timestamp'] + labels)

# Collect data for 1 minute
collected_data = []
start_time = time.time()

try:
    while time.time() - start_time < 120:  # Collect data for 1 minute
        # Read data from the Arduino serial port
        if ser.in_waiting > 0:
            
            data = ser.readline().decode('ascii').strip()  # Read and decode the data
            print("Received data:", data)  # Print data to the console for debugging
            
            # Data format: Flex:100,200,150,180,170|Accel:0.12,0.34,0.56|Gyro:0.01,-0.02,0.03
            # Parse the data to extract sensor values
            try:
                # Split the string into the different parts (flex, accel, gyro)
                flex_data = data.split('|')[0].replace('Flex:', '').split(',')
                accel_data = data.split('|')[1].replace('Accel:', '').split(',')
                gyro_data = data.split('|')[2].replace('Gyro:', '').split(',')

                # Combine all sensor data
                all_data = flex_data + accel_data + gyro_data

                # Get the current timestamp
                timestamp = time.strftime('%Y-%m-%d %H:%M:%S')

                # Add the timestamp and data to the collected data list
                collected_data.append([timestamp] + all_data)
            
            except Exception as e:
                print("Error parsing data:", e)

        time.sleep(0.001)  # Adjust the delay to match the Arduino's data transmission rate

    # Ask user if they want to keep or discard the collected data
    keep_data = input(f"Collected {len(collected_data)} entries. Do you want to keep the data? (yes/no): ").strip().lower()
    if keep_data == 'yes':
        # Write the collected data to the CSV file
        csv_writer.writerows(collected_data)
        print(f"Data saved to {label_name}.csv")
    else:
        print("Data discarded.")

except KeyboardInterrupt:
    # Handle manual exit
    print("Exiting...")
finally:
    # Close the CSV file and serial connection
    csv_file.close()
    ser.close()