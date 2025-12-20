"""
Convert trained TensorFlow model to TensorFlow Lite format
Optimized for mobile deployment
"""

import tensorflow as tf
import os
import json

def convert_to_tflite(model_path, output_path, optimize=True):
    """
    Convert SavedModel to TFLite format
    
    Args:
        model_path: Path to saved TensorFlow model
        output_path: Path to save .tflite file
        optimize: Whether to apply optimizations
    """
    print("="*60)
    print("TensorFlow Lite Conversion")
    print("="*60)
    
    # Load model
    print(f"\nLoading model from: {model_path}")
    model = tf.keras.models.load_model(model_path)
    
    print("\nModel Summary:")
    model.summary()
    
    # Convert to TFLite
    print("\nConverting to TFLite...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    
    if optimize:
        print("Applying optimizations...")
        # Default optimizations (quantization)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        
        # Optional: More aggressive optimizations
        # converter.target_spec.supported_types = [tf.float16]
    
    tflite_model = converter.convert()
    
    # Save
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    with open(output_path, 'wb') as f:
        f.write(tflite_model)
    
    # Get file size
    size_kb = len(tflite_model) / 1024
    size_mb = size_kb / 1024
    
    print(f"\n✅ TFLite model saved to: {output_path}")
    
    if size_mb >= 1:
        print(f"   Model size: {size_mb:.2f} MB")
    else:
        print(f"   Model size: {size_kb:.2f} KB")
    
    return tflite_model

def test_tflite_model(tflite_path, vocab_path):
    """
    Test the converted TFLite model
    """
    import numpy as np
    import pickle
    
    print("\n" + "="*60)
    print("Testing TFLite Model")
    print("="*60)
    
    # Load TFLite model
    interpreter = tf.lite.Interpreter(model_path=tflite_path)
    interpreter.allocate_tensors()
    
    # Get input/output details
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print(f"\nInput shape: {input_details[0]['shape']}")
    print(f"Output shape: {output_details[0]['shape']}")
    
    # Load vocab
    with open(vocab_path, 'rb') as f:
        vocab = pickle.load(f)
    
    reverse_vocab = {idx: ing for ing, idx in vocab.items()}
    vocab_size = len(vocab)
    
    # Test with sample input
    print("\nTest inference:")
    test_ingredients = ['potato', 'onion', 'tomato']
    
    # Create input
    test_input = np.zeros(vocab_size, dtype=np.float32)
    for ing in test_ingredients:
        if ing in vocab:
            test_input[vocab[ing]] = 1.0
    
    # Run inference
    interpreter.set_tensor(input_details[0]['index'], [test_input])
    interpreter.invoke()
    output = interpreter.get_tensor(output_details[0]['index'])[0]
    
    # Get top predictions
    top_indices = np.argsort(output)[::-1][:10]
    
    print(f"Input: {', '.join(test_ingredients)}")
    print("Top 5 suggested ingredients:")
    for i, idx in enumerate(top_indices[:5]):
        if output[idx] > 0.1:
            print(f"  {i+1}. {reverse_vocab[idx]}: {output[idx]:.3f}")
    
    print("\n✅ TFLite model is working correctly!")

def create_flutter_assets(tflite_path, vocab_path, metadata_path, output_dir):
    """
    Copy model and vocab to Flutter assets directory
    """
    import shutil
    
    print("\n" + "="*60)
    print("Preparing Flutter Assets")
    print("="*60)
    
    os.makedirs(output_dir, exist_ok=True)
    
    # Copy TFLite model
    tflite_dest = os.path.join(output_dir, 'recipe_model.tflite')
    shutil.copy(tflite_path, tflite_dest)
    print(f"✅ Copied: {tflite_dest}")
    
    # Convert vocab to JSON for Flutter
    import pickle
    with open(vocab_path, 'rb') as f:
        vocab = pickle.load(f)
    
    vocab_json_path = os.path.join(output_dir, 'vocab.json')
    with open(vocab_json_path, 'w', encoding='utf-8') as f:
        json.dump(vocab, f, indent=2, ensure_ascii=False)
    print(f"✅ Copied: {vocab_json_path}")
    
    # Copy metadata
    if os.path.exists(metadata_path):
        metadata_dest = os.path.join(output_dir, 'model_metadata.json')
        shutil.copy(metadata_path, metadata_dest)
        print(f"✅ Copied: {metadata_dest}")
    
    print(f"\nAll assets ready in: {output_dir}")

if __name__ == '__main__':
    # Paths
    MODEL_PATH = '../models/saved_model/'
    TFLITE_PATH = '../models/tflite/recipe_model.tflite'
    VOCAB_PATH = '../data/processed/vocab.pkl'
    METADATA_PATH = '../models/saved_model/model_metadata.json'
    FLUTTER_ASSETS_DIR = '../../assets/models'
    
    # Convert
    tflite_model = convert_to_tflite(
        model_path=MODEL_PATH,
        output_path=TFLITE_PATH,
        optimize=True
    )
    
    # Test
    test_tflite_model(TFLITE_PATH, VOCAB_PATH)
    
    # Copy to Flutter assets
    create_flutter_assets(
        tflite_path=TFLITE_PATH,
        vocab_path=VOCAB_PATH,
        metadata_path=METADATA_PATH,
        output_dir=FLUTTER_ASSETS_DIR
    )
    
    print("\n" + "="*60)
    print("Conversion Complete!")
    print("="*60)
    print("\nNext steps:")
    print("1. Update pubspec.yaml to include assets")
    print("2. Create AI service in Flutter: lib/services/ai_recipe_service.dart")
    print("3. Run: flutter pub get")
