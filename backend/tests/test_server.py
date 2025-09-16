from flask import Flask, request, jsonify
import numpy as np
import pickle

try:
    # Load models and scalers
    print("Loading model files...")
    model = pickle.load(open('model.pkl', 'rb'))
    sc = pickle.load(open('standscaler.pkl', 'rb'))
    ms = pickle.load(open('minmaxscaler.pkl', 'rb'))
    print("Model files loaded successfully!")

    # Create Flask app
    app = Flask(__name__)

    @app.route('/')
    def index():
        return "Welcome to the Crop Recommendation System!"

    @app.route("/predict", methods=['POST'])
    def predict():
        try:
            data = request.get_json()
            print(f"Received data: {data}")

            # Extract parameters from the received JSON
            N = float(data['nitrogen'])
            P = float(data['phosphorus'])
            K = float(data['potassium'])
            temp = float(data['temperature'])
            humidity = float(data['humidity'])
            ph = float(data['ph'])
            rainfall = float(data['rainfall'])
            print(f"Parsed data: {N}, {P}, {K}, {temp}, {humidity}, {ph}, {rainfall}")

            feature_list = [N, P, K, temp, humidity, ph, rainfall]
            single_pred = np.array(feature_list).reshape(1, -1)

            # Scaling the input data
            scaled_features = ms.transform(single_pred)
            final_features = sc.transform(scaled_features)
            prediction = model.predict(final_features)

            # Crop dictionary
            crop_dict = {1: "Rice", 2: "Maize", 3: "Jute", 4: "Cotton", 5: "Coconut", 6: "Papaya", 7: "Orange",
                         8: "Apple", 9: "Muskmelon", 10: "Watermelon", 11: "Grapes", 12: "Mango", 13: "Banana",
                         14: "Pomegranate", 15: "Lentil", 16: "Blackgram", 17: "Mungbean", 18: "Mothbeans",
                         19: "Pigeonpeas", 20: "Kidneybeans", 21: "Chickpea", 22: "Coffee"}

            # Get the recommendation based on the prediction
            crop = crop_dict.get(prediction[0], "Unknown crop")
            print(f"Predicted crop: {crop}")
            
            # Return the result as a JSON response
            return jsonify({'crop': crop})
        except Exception as e:
            print(f"Error in prediction: {e}")
            return jsonify({'error': str(e)}), 500

    if __name__ == "__main__":
        print("Starting Flask server...")
        app.run(debug=True, host='0.0.0.0', port=5000)
        
except Exception as e:
    print(f"Error loading model: {e}")
    import traceback
    traceback.print_exc()
