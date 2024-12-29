import pickle

# Create a simple dummy object (it can be a placeholder model)
dummy_model = {
    "name": "Dummy Model",
    "type": "RandomForestClassifier",
    "version": 1.0,
    "info": "This is a placeholder for testing purposes."
}

# Save the dummy object as a pickle file
with open("rf_model.pkl", "wb") as file:
    pickle.dump(dummy_model, file)

print("Dummy model file 'rf_model.pkl' created successfully.")
