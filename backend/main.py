from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import pickle
import os

app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Adjust for specific origins in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Path to the model file
model_path = os.path.join(os.path.dirname(__file__), "rf_model.pkl")

# Load the pickle file
try:
    with open(model_path, "rb") as file:
        model = pickle.load(file)
    print("Model loaded successfully:", model)
except FileNotFoundError:
    print(f"Error: Model file not found at {model_path}")
    model = None
except pickle.UnpicklingError:
    print("Error: Failed to unpickle the model file. Please check the file format.")
    model = None

@app.get("/")
def read_root():
    if model:
        return {"message": f"Model loaded: {model['name']}"}
    else:
        return {"message": "No model loaded."}

# Define the /latest_prediction endpoint
@app.get("/latest_prediction")
def latest_prediction():
    if model:
        # Replace with actual model prediction logic
        return {"prediction": "This is a dummy prediction."}
    else:
        return {"error": "Model not loaded"}
