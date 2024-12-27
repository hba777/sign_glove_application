from main import FastAPI
from pydantic import BaseModel
import joblib
import pandas as pd

# Load the trained model
model = joblib.load("rf_model.pkl")

# Define the input data model
class SensorData(BaseModel):
    flex_1: float
    flex_2: float
    flex_3: float
    flex_4: float
    flex_5: float
    GYRx: float
    GYRy: float
    GYRz: float

# Initialize FastAPI app
app = FastAPI()

# Define a route for predictions
@app.post("/predict/")
async def predict(data: SensorData):
    # Convert the incoming data to a DataFrame
    input_data = pd.DataFrame([data.dict()])
    
    # Predict using the loaded model
    prediction = model.predict(input_data)
    
    # Return the predicted label (encoded as a number)
    return {"predicted_label": int(prediction[0])}

# To run the API, use `uvicorn` in the terminal:
# uvicorn main:app --reload
