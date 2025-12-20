"""
Train TensorFlow model for Indian recipe generation
Uses ingredient-to-recipe embedding approach
"""

import tensorflow as tf
import numpy as np
import pickle
import os
import json
from sklearn.model_selection import train_test_split
from datetime import datetime

def encode_ingredients(ingredient_list, vocab):
    """
    Convert ingredient list to multi-hot encoding
    """
    encoding = np.zeros(len(vocab), dtype=np.float32)
    for ing in ingredient_list:
        if ing in vocab:
            encoding[vocab[ing]] = 1.0
    return encoding

def prepare_training_data(recipes, vocab):
    """
    Prepare input-output pairs for training
    
    Model learns to predict complementary ingredients:
    Input: Available ingredients (multi-hot encoded)
    Output: All ingredients in the recipe (multi-hot encoded)
    """
    X = []  # Input: subset of ingredients
    y = []  # Output: full recipe ingredients
    
    for recipe in recipes:
        ingredients = recipe['ingredients']
        
        if len(ingredients) < 3:
            continue
        
        # Full recipe encoding
        full_encoding = encode_ingredients(ingredients, vocab)
        
        # Create training samples with different ingredient subsets
        for subset_size in range(2, min(len(ingredients), 8)):
            # Use first N ingredients as input
            subset = ingredients[:subset_size]
            input_encoding = encode_ingredients(subset, vocab)
            
            X.append(input_encoding)
            y.append(full_encoding)
    
    return np.array(X), np.array(y)

def build_model(vocab_size, hidden_size=256):
    """
    Build neural network for recipe completion
    
    Architecture: Ingredient Encoder -> Dense layers -> Ingredient Decoder
    """
    model = tf.keras.Sequential([
        # Input layer
        tf.keras.layers.Input(shape=(vocab_size,), name='ingredient_input'),
        
        # Encoder: compress ingredient information
        tf.keras.layers.Dense(hidden_size, activation='relu', name='encoder_1'),
        tf.keras.layers.Dropout(0.3),
        tf.keras.layers.Dense(128, activation='relu', name='encoder_2'),
        tf.keras.layers.Dropout(0.3),
        
        # Bottleneck: learned ingredient embeddings
        tf.keras.layers.Dense(64, activation='relu', name='embedding'),
        
        # Decoder: predict complementary ingredients
        tf.keras.layers.Dense(128, activation='relu', name='decoder_1'),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(hidden_size, activation='relu', name='decoder_2'),
        
        # Output: probability of each ingredient
        tf.keras.layers.Dense(vocab_size, activation='sigmoid', name='ingredient_output')
    ], name='indian_recipe_model')
    
    return model

def train_model(recipes, vocab, epochs=30, batch_size=32, validation_split=0.2):
    """
    Train the recipe generation model
    """
    print("\n" + "="*60)
    print("Preparing Training Data")
    print("="*60)
    
    X, y = prepare_training_data(recipes, vocab)
    print(f"Training samples: {len(X)}")
    print(f"Vocabulary size: {len(vocab)}")
    
    # Split data
    X_train, X_val, y_train, y_val = train_test_split(
        X, y, test_size=validation_split, random_state=42
    )
    
    print(f"Train samples: {len(X_train)}")
    print(f"Validation samples: {len(X_val)}")
    
    # Build model
    print("\n" + "="*60)
    print("Building Model")
    print("="*60)
    
    model = build_model(vocab_size=len(vocab))
    
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
        loss='binary_crossentropy',
        metrics=[
            'accuracy',
            tf.keras.metrics.Precision(name='precision'),
            tf.keras.metrics.Recall(name='recall')
        ]
    )
    
    print(model.summary())
    
    # Callbacks
    callbacks = [
        tf.keras.callbacks.EarlyStopping(
            monitor='val_loss',
            patience=5,
            restore_best_weights=True,
            verbose=1
        ),
        tf.keras.callbacks.ModelCheckpoint(
            '../models/saved_model/best_model.h5',
            monitor='val_loss',
            save_best_only=True,
            verbose=1
        ),
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor='val_loss',
            factor=0.5,
            patience=3,
            min_lr=0.00001,
            verbose=1
        )
    ]
    
    # Train
    print("\n" + "="*60)
    print("Training Model")
    print("="*60)
    
    history = model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=epochs,
        batch_size=batch_size,
        callbacks=callbacks,
        verbose=1
    )
    
    return model, history

def evaluate_model(model, recipes, vocab, num_samples=5):
    """
    Evaluate model on sample recipes
    """
    print("\n" + "="*60)
    print("Model Evaluation")
    print("="*60)
    
    reverse_vocab = {idx: ing for ing, idx in vocab.items()}
    
    for i in range(min(num_samples, len(recipes))):
        recipe = recipes[i]
        ingredients = recipe['ingredients']
        
        if len(ingredients) < 3:
            continue
        
        # Use first 3 ingredients as input
        input_ingredients = ingredients[:3]
        input_encoding = encode_ingredients(input_ingredients, vocab)
        
        # Predict
        output = model.predict(np.array([input_encoding]), verbose=0)[0]
        
        # Get top predictions
        top_indices = np.argsort(output)[::-1][:10]
        predictions = [reverse_vocab[idx] for idx in top_indices if output[idx] > 0.3]
        
        print(f"\nRecipe: {recipe['name']}")
        print(f"Input ingredients: {', '.join(input_ingredients)}")
        print(f"Actual recipe: {', '.join(ingredients)}")
        print(f"AI suggestions: {', '.join(predictions[:5])}")

def save_model_metadata(vocab, history, output_dir):
    """
    Save model metadata for Flutter integration
    """
    metadata = {
        'model_version': '1.0.0',
        'training_date': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        'vocab_size': len(vocab),
        'architecture': 'ingredient_embedding',
        'dataset': 'indian_recipes',
        'final_accuracy': float(history.history['accuracy'][-1]),
        'final_val_accuracy': float(history.history['val_accuracy'][-1]),
    }
    
    with open(os.path.join(output_dir, 'model_metadata.json'), 'w') as f:
        json.dump(metadata, f, indent=2)
    
    print(f"\n✅ Model metadata saved")

if __name__ == '__main__':
    print("="*60)
    print("Indian Recipe AI Model Training")
    print("="*60)
    
    # Load preprocessed data
    print("\nLoading preprocessed data...")
    
    with open('../data/processed/recipes.pkl', 'rb') as f:
        recipes = pickle.load(f)
    
    with open('../data/processed/vocab.pkl', 'rb') as f:
        vocab = pickle.load(f)
    
    print(f"✅ Loaded {len(recipes)} recipes")
    print(f"✅ Vocabulary: {len(vocab)} ingredients")
    
    # Train model
    model, history = train_model(
        recipes=recipes,
        vocab=vocab,
        epochs=30,
        batch_size=32,
        validation_split=0.2
    )
    
    # Evaluate
    evaluate_model(model, recipes, vocab)
    
    # Save
    os.makedirs('../models/saved_model', exist_ok=True)
    model.save('../models/saved_model/')
    
    save_model_metadata(vocab, history, '../models/saved_model')
    
    print("\n" + "="*60)
    print("Training Complete!")
    print("="*60)
    print("\n✅ Model saved to: ../models/saved_model/")
    print("\nNext steps:")
    print("1. Run: python convert_to_tflite.py")
