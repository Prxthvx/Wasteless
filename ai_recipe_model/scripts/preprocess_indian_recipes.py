"""
Preprocessing script for Indian recipe datasets
Supports CSV, JSON, and Excel formats
"""

import json
import pickle
import os
import pandas as pd
from collections import Counter
import re
from typing import Dict, List, Tuple

def clean_ingredient(ingredient: str) -> str:
    """
    Clean and normalize ingredient names for Indian recipes
    Handles Hindi/English mixed text, measurements, etc.
    """
    if not ingredient or not isinstance(ingredient, str):
        return ""
    
    ingredient = ingredient.lower().strip()
    
    # Remove measurements (both metric and Indian)
    measurements = [
        r'\d+(\.\d+)?', # numbers
        r'\b(cup|cups|tbsp|tsp|tablespoon|teaspoon|oz|lb|kg|g|gm|gram|grams|ml|liter|litre|l)\b',
        r'\b(pinch|handful|bunch|to taste|as needed|as required)\b',
        r'\b(small|medium|large|big|chopped|diced|sliced|minced|grated|crushed|paste)\b',
    ]
    
    for pattern in measurements:
        ingredient = re.sub(pattern, '', ingredient)
    
    # Remove special characters but keep hyphens for compound names
    ingredient = re.sub(r'[^\w\s-]', '', ingredient)
    
    # Remove extra spaces
    ingredient = ' '.join(ingredient.split())
    
    # Remove very short words (likely measurement remnants)
    words = ingredient.split()
    words = [w for w in words if len(w) > 2 or w in ['dal', 'oil', 'ghee', 'tea']]
    ingredient = ' '.join(words)
    
    return ingredient.strip()

def normalize_ingredient(ingredient: str) -> str:
    """
    Normalize ingredient variations to standard names
    """
    # Common Indian ingredient variations
    normalizations = {
        'tomatos': 'tomato',
        'tomatoes': 'tomato',
        'onions': 'onion',
        'potatos': 'potato',
        'potatoes': 'potato',
        'coriander leaves': 'coriander',
        'curry leaves': 'curry leaf',
        'green chili': 'green chilli',
        'green chilies': 'green chilli',
        'red chili': 'red chilli',
        'red chilies': 'red chilli',
        'ginger garlic': 'ginger garlic paste',
        'turmeric powder': 'turmeric',
        'cumin seeds': 'cumin',
        'mustard seeds': 'mustard',
        'coriander powder': 'coriander',
        'red chilli powder': 'red chilli',
        'garam masala powder': 'garam masala',
    }
    
    return normalizations.get(ingredient, ingredient)

def load_recipes_from_csv(filepath: str) -> List[Dict]:
    """Load recipes from CSV file"""
    print(f"Loading CSV: {filepath}")
    df = pd.read_csv(filepath)
    
    recipes = []
    for _, row in df.iterrows():
        # Try different possible column names
        ingredients_raw = (
            row.get('ingredients') or 
            row.get('Ingredients') or 
            row.get('ingredient_list') or
            ""
        )
        
        # Handle different ingredient formats
        if isinstance(ingredients_raw, str):
            if ',' in ingredients_raw:
                ingredients = [i.strip() for i in ingredients_raw.split(',')]
            elif '\n' in ingredients_raw:
                ingredients = [i.strip() for i in ingredients_raw.split('\n')]
            else:
                ingredients = [ingredients_raw]
        else:
            ingredients = []
        
        recipe = {
            'name': row.get('name') or row.get('Name') or row.get('recipe_name') or 'Unknown',
            'ingredients': ingredients,
            'instructions': row.get('instructions') or row.get('Instructions') or row.get('steps') or '',
            'cuisine': row.get('cuisine') or row.get('Cuisine') or 'Indian',
            'course': row.get('course') or row.get('Course') or 'Main Course',
            'diet': row.get('diet') or row.get('Diet') or 'Vegetarian',
            'prep_time': row.get('prep_time') or row.get('PrepTime') or '30',
            'cook_time': row.get('cook_time') or row.get('CookTime') or '30',
        }
        
        recipes.append(recipe)
    
    return recipes

def load_recipes_from_json(filepath: str) -> List[Dict]:
    """Load recipes from JSON file"""
    print(f"Loading JSON: {filepath}")
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Handle different JSON structures
    if isinstance(data, list):
        recipes = data
    elif isinstance(data, dict) and 'recipes' in data:
        recipes = data['recipes']
    else:
        recipes = [data]
    
    return recipes

def load_recipes_from_excel(filepath: str) -> List[Dict]:
    """Load recipes from Excel file"""
    print(f"Loading Excel: {filepath}")
    df = pd.read_excel(filepath)
    return load_recipes_from_csv(filepath)  # Reuse CSV logic

def preprocess_recipes(
    data_dir: str, 
    min_ingredients: int = 3, 
    max_ingredients: int = 20
) -> Tuple[List[Dict], Dict[str, int]]:
    """
    Load and preprocess all recipe files in data directory
    """
    all_recipes = []
    all_ingredients = []
    
    # Load all files in data/raw directory
    for filename in os.listdir(data_dir):
        filepath = os.path.join(data_dir, filename)
        
        try:
            if filename.endswith('.csv'):
                recipes = load_recipes_from_csv(filepath)
            elif filename.endswith('.json'):
                recipes = load_recipes_from_json(filepath)
            elif filename.endswith(('.xlsx', '.xls')):
                recipes = load_recipes_from_excel(filepath)
            else:
                continue
            
            print(f"Loaded {len(recipes)} recipes from {filename}")
            
            # Process each recipe
            for recipe in recipes:
                ingredients = recipe.get('ingredients', [])
                
                if not ingredients:
                    continue
                
                # Clean ingredients
                cleaned = []
                for ing in ingredients:
                    clean_ing = clean_ingredient(str(ing))
                    if clean_ing and len(clean_ing) > 2:
                        normalized = normalize_ingredient(clean_ing)
                        cleaned.append(normalized)
                
                # Filter by ingredient count
                if len(cleaned) < min_ingredients or len(cleaned) > max_ingredients:
                    continue
                
                recipe['ingredients'] = cleaned
                all_recipes.append(recipe)
                all_ingredients.extend(cleaned)
        
        except Exception as e:
            print(f"Error processing {filename}: {e}")
            continue
    
    print(f"\nTotal recipes processed: {len(all_recipes)}")
    
    # Build vocabulary (keep ingredients that appear at least 5 times for Indian recipes)
    ingredient_counts = Counter(all_ingredients)
    
    # Filter ingredients by minimum count
    filtered_ingredients = [ing for ing, count in ingredient_counts.items() if count >= 5]
    
    # Create vocabulary with CONSECUTIVE indices (0, 1, 2, 3...)
    vocab = {ing: idx for idx, ing in enumerate(filtered_ingredients)}
    
    print(f"Vocabulary size: {len(vocab)} ingredients")
    print(f"\nTop 20 ingredients:")
    for ing, count in ingredient_counts.most_common(20):
        print(f"  {ing}: {count}")
    
    return all_recipes, vocab

def save_processed_data(recipes: List[Dict], vocab: Dict[str, int], output_dir: str):
    """Save preprocessed data"""
    os.makedirs(output_dir, exist_ok=True)
    
    # Save as pickle for Python
    with open(os.path.join(output_dir, 'recipes.pkl'), 'wb') as f:
        pickle.dump(recipes, f)
    
    with open(os.path.join(output_dir, 'vocab.pkl'), 'wb') as f:
        pickle.dump(vocab, f)
    
    # Save vocab as JSON for Flutter
    with open(os.path.join(output_dir, 'vocab.json'), 'w', encoding='utf-8') as f:
        json.dump(vocab, f, indent=2, ensure_ascii=False)
    
    # Save sample recipes as JSON for inspection
    sample_recipes = recipes[:10] if len(recipes) > 10 else recipes
    with open(os.path.join(output_dir, 'sample_recipes.json'), 'w', encoding='utf-8') as f:
        json.dump(sample_recipes, f, indent=2, ensure_ascii=False)
    
    print(f"\n✅ Saved preprocessed data to {output_dir}")
    print(f"   - recipes.pkl ({len(recipes)} recipes)")
    print(f"   - vocab.pkl ({len(vocab)} ingredients)")
    print(f"   - vocab.json (for Flutter)")
    print(f"   - sample_recipes.json (10 sample recipes)")

if __name__ == '__main__':
    # Configuration
    DATA_DIR = '../data/raw'
    OUTPUT_DIR = '../data/processed'
    
    print("=" * 60)
    print("Indian Recipe Dataset Preprocessing")
    print("=" * 60)
    
    # Preprocess
    recipes, vocab = preprocess_recipes(
        data_dir=DATA_DIR,
        min_ingredients=3,
        max_ingredients=20
    )
    
    # Save
    save_processed_data(recipes, vocab, OUTPUT_DIR)
    
    print("\n" + "=" * 60)
    print("Preprocessing Complete!")
    print("=" * 60)
    print("\nNext steps:")
    print("1. Review sample_recipes.json to verify data quality")
    print("2. Run: python train_model.py")
