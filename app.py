from flask import Flask, request, jsonify
import numpy as np
import tensorflow as tf
from sklearn.preprocessing import MinMaxScaler
from tensorflow.keras.models import load_model
from tensorflow.keras.losses import MeanSquaredError
import cv2
from pathlib import Path
import os
class LeafExtractor:
    def __init__(self):
        self.target_size = 500  
        
    def preprocess_image(self, image):
        #Scale image to standard size while maintaining aspect ratio
        height, width = image.shape[:2]
        scale = self.target_size / max(height, width)
        new_width = int(width * scale)
        new_height = int(height * scale)
        return cv2.resize(image, (new_width, new_height))
        
    def segment_plant(self, image):
        """Separate plant from background using Otsu's method"""
        # Convert to grayscale
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        
        # Apply Gaussian blur to reduce noise
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)
        
        # Apply Otsu's thresholding
        _, binary = cv2.threshold(blurred, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        
        # Create mask for the plant
        mask = binary > 0
        
        # Apply mask to original image
        result = image.copy()
        result[~mask] = 255  # Set background to white
        return result, binary
        
    def create_markers(self, binary):
        """Create internal and external markers for watershed segmentation"""
        # Create internal markers (possible leaves)
        kernel = np.zeros((30, 30), dtype=np.uint8)
        cv2.line(kernel, (15, 0), (15, 29), 1, 1)  # Vertical line
        cv2.line(kernel, (0, 15), (29, 15), 1, 1)  # Horizontal line
        internal_markers = cv2.erode(binary, kernel, iterations=1)
        
        # Create external markers (background)
        external_markers = ~binary
        
        return internal_markers, external_markers
        
    def process_stems(self, image, binary):
        """Dam up stems and branches in gradient image"""
        # Create gradient image
        gradient = cv2.morphologyEx(binary, cv2.MORPH_GRADIENT, np.ones((3,3), np.uint8))
        
        # Create binary image from gradient
        _, stem_binary = cv2.threshold(gradient, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        
        # Close gaps in stems
        closed = cv2.morphologyEx(stem_binary, cv2.MORPH_CLOSE, np.ones((5,5), np.uint8))
        
        # Fill stems with maximum value in gradient image
        gradient[closed > 0] = 255
        
        return gradient
        
    def clean_leaf_image(self, leaf_image):
        """Clean individual leaf image by removing stems and other artifacts"""
        # Create binary image
        gray = cv2.cvtColor(leaf_image, cv2.COLOR_BGR2GRAY)
        _, binary = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        
        # Determine core leaf body
        height, width = binary.shape
        struct_size = max(width, height) // 8
        kernel = np.ones((struct_size, struct_size), np.uint8)
        core_body = cv2.morphologyEx(binary, cv2.MORPH_OPEN, kernel)
        
        # Get border regions
        border_regions = binary - core_body
        
        # Label border regions
        num_labels, labels = cv2.connectedComponents(border_regions.astype(np.uint8))
        
        # Examine each region for connectivity
        for label in range(1, num_labels):
            region = labels == label
            dilated_core = cv2.dilate(core_body, np.ones((3,3), np.uint8))
            connectivity = np.sum(region & dilated_core) / np.sum(region)
            
            # Remove regions with low connectivity
            if connectivity < 0.16:  # Based on paper's threshold
                leaf_image[region] = 255
                
        return leaf_image
        
    def extract_leaves(self, image):
        """Extract individual leaves from whole plant image"""
        # Preprocess image
        processed = self.preprocess_image(image)
        
        # Segment plant from background
        plant_image, binary = self.segment_plant(processed)
        
        # Create markers for watershed
        internal_markers, external_markers = self.create_markers(binary)
        
        # Process stems and create gradient image
        gradient = self.process_stems(plant_image, binary)
        
        # Prepare markers for watershed
        markers = np.zeros(binary.shape, dtype=np.int32)
        markers[internal_markers > 0] = 2
        markers[external_markers > 0] = 1
        
        # Apply watershed
        gradient_colored = cv2.cvtColor(gradient, cv2.COLOR_GRAY2BGR)
        cv2.watershed(gradient_colored, markers)
        
        # Extract individual leaves
        leaf_images = []
        for label in range(2, markers.max() + 1):
            # Get region for current leaf
            leaf_mask = markers == label
            
            # Calculate bounding box
            coords = np.column_stack(np.where(leaf_mask))
            if len(coords) == 0:
                continue
                
            min_y, min_x = coords.min(axis=0)
            max_y, max_x = coords.max(axis=0)
            
            # Add padding
            padding = 0.1  # 10% padding
            pad_x = int((max_x - min_x) * padding)
            pad_y = int((max_y - min_y) * padding)
            
            min_x = max(0, min_x - pad_x)
            min_y = max(0, min_y - pad_y)
            max_x = min(binary.shape[1], max_x + pad_x)
            max_y = min(binary.shape[0], max_y + pad_y)
            
            # Extract leaf region
            leaf = plant_image[min_y:max_y, min_x:max_x].copy()
            
            # Check if region is large enough
            if leaf.shape[0] * leaf.shape[1] >= 961:  # 31x31 minimum size
                # Clean the leaf image
                cleaned_leaf = self.clean_leaf_image(leaf)
                leaf_images.append(cleaned_leaf)
                
        return leaf_images

class DiseaseClassifier:
    def __init__(self, model_path):
        self.model = load_model(model_path)
        self.target_size = (224, 224)
        self.class_names = [
            'Pepper__bell___Bacterial_spot',
             'Pepper__bell___healthy',
             'Potato___Early_blight',
             'Potato___Late_blight',
             'Potato___healthy',
             'Tomato_Bacterial_spot',
             'Tomato_Early_blight',
             'Tomato_Late_blight',
             'Tomato_Leaf_Mold',
             'Tomato_Septoria_leaf_spot',
             'Tomato_Spider_mites_Two_spotted_spider_mite',
             'Tomato__Target_Spot',
             'Tomato__Tomato_YellowLeaf__Curl_Virus',
             'Tomato__Tomato_mosaic_virus',
             'Tomato_healthy']
        
    def preprocess_image(self, image):
        image = cv2.resize(image, self.target_size)
        image = image.astype('float32') / 255.0
        image = np.expand_dims(image, axis=0)
        return image

    def predict(self, image):
        processed_image = self.preprocess_image(image)
        prediction = self.model.predict(processed_image)
        predicted_class_index = np.argmax(prediction)  # Get class index
        predicted_class_name = self.class_names[predicted_class_index]  # Get class name
        confidence = float(np.max(prediction))  # Get confidence score

        return {
            'predicted_class': predicted_class_name,
            'confidence': confidence
        }
    

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

#------------------------------------------------------------
@app.route('/analyze', methods=['POST'])
def analyze_plant():
    if 'image' not in request.files:
        return jsonify({'error': 'No image file provided'}), 400
        
    file = request.files['image']
    image_array = cv2.imdecode(
        np.frombuffer(file.read(), np.uint8),
        cv2.IMREAD_COLOR
    )
    
    # Extract leaves
    leaf_images = leaf_extractor.extract_leaves(image_array)
    
    if not leaf_images:
        return jsonify({'error': 'No leaves detected in image'}), 400
    
    # Analyze each leaf
    results = []
    for i, leaf_image in enumerate(leaf_images):
        prediction = disease_classifier.predict(leaf_image)
        
        # Save leaf image
        leaf_filename = f'leaf_{i}.jpg'
        cv2.imwrite(os.path.join('extracted_leaves', leaf_filename), leaf_image)
        
        results.append({
            'leaf_number': i + 1,
            'leaf_image': leaf_filename,
            'analysis': prediction
        })
    
    return jsonify({
        'total_leaves': len(leaf_images),
        'results': results
    })
if __name__ == "__main__":
    print("Loading components...")
    leaf_extractor = LeafExtractor()
    disease_classifier = DiseaseClassifier('disease_detection.h5')
    os.makedirs('extracted_leaves', exist_ok=True)
    app.run(debug=True, port=5000)
