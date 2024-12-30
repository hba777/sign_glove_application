from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import joblib
import pandas as pd

# Load the trained model
model = joblib.load("rf_model.pkl")

app = FastAPI()

# Configure CORS to allow requests from any origin
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow requests from any origin
    allow_credentials=True,
    allow_methods=["*"],  # Allow all HTTP methods
    allow_headers=["*"],  # Allow all HTTP headers
)

@app.post("/predict")
async def predict(data: dict):
    try:
        # Parse the incoming data from sensor_values
        sensor_values = data.get("sensor_values", "")
        
        # Assuming the data is sent in the format "Flex:794,798,830,794,771|Accel:-0.87,-0.69,10.60|Gyro:-0.04,0.01,-0.01"
        # Split the data by "|"
        flex_data, accel_data, gyro_data = sensor_values.split("|")
        
        # Extract the values from each section by splitting by commas
        flex_values = list(map(int, flex_data.replace("Flex:", "").split(",")))
        accel_values = list(map(float, accel_data.replace("Accel:", "").split(",")))
        gyro_values = list(map(float, gyro_data.replace("Gyro:", "").split(",")))
        
        # Create the DataFrame with the appropriate column names
        input_data = pd.DataFrame([flex_values + accel_values + gyro_values], columns=[
            "Flex1", "Flex2", "Flex3", "Flex4", "Flex5",
            "AccelX", "AccelY", "AccelZ",
            "GyroX", "GyroY", "GyroZ"
        ])
        
        # Predict using the model
        prediction = model.predict(input_data)
        
        return {"label": str(prediction[0])}
    
    except Exception as e:
        return {"error": str(e)}
