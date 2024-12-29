from fastapi import FastAPI
from pydantic import BaseModel
from typing import List
import pickle
import numpy as np

# Load the trained Random Forest model
model = pickle.load(open("rf_model.pkl", "rb"))

# Initialize the FastAPI app
app = FastAPI()

# Define the request schema using Pydantic
class SensorData(BaseModel):
    Flex: List[int]
    Accel: List[float]
    Gyro: List[float]

# Define the prediction route
@app.post("/predict/")
async def predict(data: SensorData):
    try:
        # Combine the input data into a single feature vector
        feature_vector = data.Flex + data.Accel + data.Gyro
        feature_vector = np.array(feature_vector).reshape(1, -1)

        # Perform the prediction
        prediction = model.predict(feature_vector)

        # Return the prediction as a response
        return {"prediction": prediction.tolist()}
    except Exception as e:
        return {"error": str(e)}

# Run the server
# To run the app, use: uvicorn main:app --host 0.0.0.0 --port 8000
