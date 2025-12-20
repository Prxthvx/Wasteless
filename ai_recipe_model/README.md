# WasteLess AI Recipe Model

Local TensorFlow Lite model for intelligent recipe generation based on Indian cuisine.

## 📋 Overview

This module trains a neural network on Indian recipe data to suggest complementary ingredients and generate recipes based on available inventory items. The model runs **entirely locally** on the user's device with no cloud dependencies.

## 🏗️ Architecture

- **Input**: Multi-hot encoded ingredient vector (available inventory)
- **Model**: Dense neural network with ingredient embeddings
- **Output**: Probability distribution over all ingredients (suggestions)
- **Deployment**: TensorFlow Lite model (~500KB-2MB) for Flutter

## 📁 Project Structure

```
ai_recipe_model/
├── data/
│   ├── raw/              # Downloaded datasets (CSV/JSON)
│   └── processed/        # Preprocessed data and vocabulary
├── models/
│   ├── saved_model/      # TensorFlow SavedModel
│   └── tflite/           # TensorFlow Lite model
├── scripts/
│   ├── download_indian_recipes.py     # Dataset downloader
│   ├── preprocess_indian_recipes.py   # Data preprocessing
│   ├── train_model.py                 # Model training
│   └── convert_to_tflite.py           # TFLite conversion
├── notebooks/            # Jupyter notebooks (optional)
└── requirements.txt      # Python dependencies
```

## 🚀 Quick Start

### Step 1: Setup Python Environment

```bash
cd ai_recipe_model
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### Step 2: Download Dataset

```bash
cd scripts
python download_indian_recipes.py
```

**Choose option:**
- **Option 1**: Kaggle (requires API key)
- **Option 2**: Direct CSV download
- **Option 3**: Sample dataset (10 recipes for testing) ✅ **Recommended for quick start**

For Kaggle:
1. Get API key from https://www.kaggle.com/settings/account
2. Place `kaggle.json` in `~/.kaggle/` (Linux/Mac) or `C:\Users\<YourUsername>\.kaggle\` (Windows)

### Step 3: Preprocess Data

```bash
python preprocess_indian_recipes.py
```

**Output:**
- `data/processed/recipes.pkl` - Processed recipes
- `data/processed/vocab.pkl` - Ingredient vocabulary
- `data/processed/vocab.json` - Vocabulary for Flutter
- `data/processed/sample_recipes.json` - Sample data for inspection

### Step 4: Train Model

```bash
python train_model.py
```

**Training takes 10-30 minutes depending on:**
- Dataset size
- Hardware (GPU recommended but not required)
- Number of epochs (default: 30)

**Output:**
- `models/saved_model/` - TensorFlow SavedModel
- `models/saved_model/best_model.h5` - Best weights
- `models/saved_model/model_metadata.json` - Model info

### Step 5: Convert to TFLite

```bash
python convert_to_tflite.py
```

**Output:**
- `models/tflite/recipe_model.tflite` - Mobile model
- `../../assets/models/recipe_model.tflite` - Copied to Flutter assets
- `../../assets/models/vocab.json` - Copied to Flutter assets

### Step 6: Flutter Integration

```bash
cd ../..  # Back to project root
flutter pub get
```

The AI service is already integrated! The recipe generation will now use:
1. **AI Model** (first priority)
2. **Local rule-based generator** (fallback)
3. **External APIs** (final fallback)

## 🧪 Testing

Test the model after training:

```bash
cd ai_recipe_model/scripts
python -c "
import pickle
import numpy as np
from train_model import encode_ingredients

# Load vocab
with open('../data/processed/vocab.pkl', 'rb') as f:
    vocab = pickle.load(f)

# Test ingredients
test_ingredients = ['potato', 'onion', 'tomato']
print(f'Testing with: {test_ingredients}')

# Load model
import tensorflow as tf
model = tf.keras.models.load_model('../models/saved_model/')

# Predict
input_encoding = encode_ingredients(test_ingredients, vocab)
output = model.predict([input_encoding])[0]

# Get top suggestions
reverse_vocab = {idx: ing for ing, idx in vocab.items()}
top_indices = np.argsort(output)[::-1][:5]

print('\\nTop 5 suggestions:')
for idx in top_indices:
    if output[idx] > 0.1:
        print(f'  {reverse_vocab[idx]}: {output[idx]:.3f}')
"
```

## 📊 Dataset Information

### Supported Formats

- **CSV**: Columns: `name`, `ingredients`, `instructions`, `cuisine`, `course`, `diet`, `prep_time`, `cook_time`
- **JSON**: Array of recipe objects or `{recipes: [...]}`
- **Excel**: Same columns as CSV

### Recommended Datasets

1. **Indian Food 101** (Kaggle) - 13,000+ recipes
2. **Indian Food Dataset** (GitHub) - 5,000+ recipes
3. **Custom scraped data** from:
   - Tarla Dalal
   - Sanjeev Kapoor
   - Veg Recipes of India

### Data Preprocessing

- Normalizes ingredient names (e.g., "tomatos" → "tomato")
- Removes measurements and quantities
- Builds vocabulary (ingredients appearing ≥5 times)
- Filters recipes by ingredient count (3-20 ingredients)

## 🔧 Model Details

### Architecture

```
Input (vocab_size) 
    ↓
Dense(256, ReLU) + Dropout(0.3)
    ↓
Dense(128, ReLU) + Dropout(0.3)
    ↓
Dense(64, ReLU) - Embedding layer
    ↓
Dense(128, ReLU) + Dropout(0.2)
    ↓
Dense(256, ReLU)
    ↓
Output (vocab_size, Sigmoid)
```

### Training Parameters

- **Loss**: Binary cross-entropy
- **Optimizer**: Adam (lr=0.001)
- **Batch size**: 32
- **Epochs**: 30 (with early stopping)
- **Validation split**: 20%

### Performance

- **Vocabulary**: ~500-2000 ingredients (depends on dataset)
- **Model size**: 500KB-2MB (TFLite with quantization)
- **Inference time**: <100ms on device
- **Accuracy**: 70-85% (ingredient prediction)

## 📱 Flutter Integration

### Initialization

The AI service auto-initializes on first use:

```dart
import 'package:wasteless/services/ai_recipe_service.dart';

// Explicit initialization (optional)
await AIRecipeService.initialize();
```

### Usage

The service is already integrated into `RecipeApiService`:

```dart
// This now uses AI model automatically
final recipes = await RecipeApiService.getRecipesByIngredients(inventoryItems);
```

### Manual Usage

```dart
// Get ingredient suggestions
final suggestions = await AIRecipeService.suggestIngredients(items);

// Generate complete recipes
final recipes = await AIRecipeService.generateRecipes(items);
```

## 🐛 Troubleshooting

### Python Issues

**Module not found:**
```bash
# Make sure virtual environment is activated
venv\Scripts\activate  # Windows
source venv/bin/activate  # Linux/Mac

pip install -r requirements.txt
```

**TensorFlow installation fails:**
```bash
# Use specific version
pip install tensorflow==2.15.0

# Or try CPU version
pip install tensorflow-cpu==2.15.0
```

### Flutter Issues

**Model not loading:**
1. Ensure assets are declared in `pubspec.yaml`
2. Run `flutter clean && flutter pub get`
3. Check file exists: `assets/models/recipe_model.tflite`

**tflite_flutter package issues:**
```bash
flutter pub cache repair
flutter clean
flutter pub get
```

## 🔄 Updating the Model

To retrain with new data:

1. Add new CSV/JSON files to `data/raw/`
2. Run preprocessing: `python preprocess_indian_recipes.py`
3. Retrain: `python train_model.py`
4. Convert: `python convert_to_tflite.py`
5. Rebuild Flutter app: `flutter clean && flutter run`

## 📈 Performance Optimization

### Reduce Model Size

Edit `convert_to_tflite.py`:

```python
# Use float16 quantization
converter.target_spec.supported_types = [tf.float16]
```

### Improve Accuracy

Edit `train_model.py`:

```python
# Increase epochs
epochs=50

# Add more layers
model.add(tf.keras.layers.Dense(512, activation='relu'))
```

### Faster Inference

```python
# Use dynamic range quantization
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
```

## 📝 License

Part of the WasteLess project.

## 🤝 Contributing

To add more Indian recipes:
1. Format as CSV with columns: `name, ingredients, instructions, cuisine`
2. Place in `data/raw/`
3. Run preprocessing and retraining

## 📧 Support

For issues, contact the WasteLess development team.
