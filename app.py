from flask import Flask, request, jsonify
import numpy as np
import tensorflow as tf
from sklearn.preprocessing import MinMaxScaler
from tensorflow.keras.models import load_model
from tensorflow.keras.losses import MeanSquaredError

app = Flask(__name__)
FIELD_CAPACITY = 0.35  # Maximum soil moisture (m³/m³)
ROOT_DEPTH = 0.6  # Root zone depth (meters)
SOIL_TYPE_FACTOR = 1000  # Converts m³/m³ to mm
DAYS_NUM = 7  # Number of days to predict


# Charger le modèle entraîné
model = load_model('fine_tuned_model.h5', custom_objects={'mse': MeanSquaredError()})

# Normaliser les données (min-max scaling)
scaler = MinMaxScaler()
target_scaler = MinMaxScaler()

# Définition des features
features = [
    "ALLSKY_SFC_SW_DWN", "ALLSKY_KT", "ALLSKY_SFC_LW_DWN",
    "T2MDEW", "TS", "WS10M", "PRECTOTCORR", "RH2M"
]

@app.route("/predict", methods=["POST"])
def predict():
    try:
        data = request.get_json()
        if not data or "sequence" not in data:
            return jsonify({"error": "Invalid input, expected 'sequence' key"}), 400

        sequence = np.array(data["sequence"])
        if sequence.shape != (7, 8):
            return jsonify({"error": "Expected input shape (7, 8)"}), 400

        # Normalisation dynamique
        feature_min = sequence.min(axis=0)  # Min par colonne (feature-wise)
        feature_max = sequence.max(axis=0)  # Max par colonne (feature-wise)

        # Éviter la division par zéro si min == max
        feature_range = feature_max - feature_min
        feature_range[feature_range == 0] = 1  # Pour éviter division par zéro

        sequence = (sequence - feature_min) / feature_range
        sequence = np.expand_dims(sequence, axis=0)  # Ajouter la dimension batch

        # Prédiction
        prediction = model.predict(sequence)
        
        # Dénormalisation de la prédiction
        predicted_value = prediction[0, 0] * (feature_max[-1] - feature_min[-1]) + feature_min[-1]
        water_needed = (FIELD_CAPACITY - predicted_value.flatten()) * ROOT_DEPTH * SOIL_TYPE_FACTOR * DAYS_NUM
        water_needed = np.maximum(water_needed, 0)
        
        return jsonify({"SoilMoistureIndex": float(predicted_value),
                        "Water Needed for Next 7 Days(mm):": water_needed[0]})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True)
