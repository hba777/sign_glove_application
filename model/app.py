import joblib
import pandas as pd
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import numpy as np

# Load the trained model
model = joblib.load("rf_model.pkl")

# Initialize FastAPI app
app = FastAPI()

# Define a Pydantic model for the input data format
class SensorData(BaseModel):
    flex1: float
    flex2: float
    flex3: float
    flex4: float
    flex5: float
    accelX: float
    accelY: float
    accelZ: float
    gyroX: float
    gyroY: float
    gyroZ: float

# Endpoint to receive sensor data and return prediction
@app.post("/predict/")
async def predict(sensor_data: SensorData):
    # Convert the received data to a DataFrame
    input_data = pd.DataFrame([[
        sensor_data.flex1, sensor_data.flex2, sensor_data.flex3, sensor_data.flex4, sensor_data.flex5,
        sensor_data.accelX, sensor_data.accelY, sensor_data.accelZ, sensor_data.gyroX, sensor_data.gyroY, sensor_data.gyroZ
    ]], columns=["Flex1", "Flex2", "Flex3", "Flex4", "Flex5", "AccelX", "AccelY", "AccelZ", "GyroX", "GyroY", "GyroZ"])

    try:
        # Make a prediction using the loaded model
        prediction = model.predict(input_data)
        predicted_label = int(prediction[0])

        # Return the predicted label as a JSON response
        return {"predicted_label": predicted_label}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error making prediction: {e}")

# Run the app using Uvicorn (use this in the terminal)
# uvicorn main:app --host 0.0.0.0 --port 8000 --reload
