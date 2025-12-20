"""
Download Indian recipe datasets from various sources
Supports Kaggle datasets and direct CSV downloads
"""

import os
import requests
from tqdm import tqdm
import zipfile
import shutil

def download_file(url, filename, description="Downloading"):
    """Download file with progress bar"""
    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()
        
        total_size = int(response.headers.get('content-length', 0))
        
        os.makedirs(os.path.dirname(filename), exist_ok=True)
        
        with open(filename, 'wb') as file, tqdm(
            desc=description,
            total=total_size,
            unit='iB',
            unit_scale=True,
            unit_divisor=1024,
        ) as bar:
            for data in response.iter_content(chunk_size=1024):
                size = file.write(data)
                bar.update(size)
        
        print(f"✅ Downloaded: {filename}")
        return True
    
    except Exception as e:
        print(f"❌ Error downloading {filename}: {e}")
        return False

def extract_zip(zip_path, extract_to):
    """Extract ZIP file"""
    try:
        print(f"Extracting {os.path.basename(zip_path)}...")
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(extract_to)
        print(f"✅ Extracted to: {extract_to}")
        return True
    except Exception as e:
        print(f"❌ Error extracting {zip_path}: {e}")
        return False

def download_kaggle_dataset():
    """
    Download Indian Food Dataset from Kaggle
    
    NOTE: You need Kaggle API credentials
    1. Go to https://www.kaggle.com/settings/account
    2. Click "Create New API Token"
    3. Download kaggle.json and place it in ~/.kaggle/kaggle.json (Linux/Mac)
       or C:\\Users\\<YourUsername>\\.kaggle\\kaggle.json (Windows)
    """
    try:
        import kaggle
        
        print("\n" + "="*60)
        print("Downloading from Kaggle: Indian Food Dataset")
        print("="*60)
        
        # Download Indian Food 101 dataset
        dataset = "nehaprabhavalkar/indian-food-101"
        output_dir = "../data/raw"
        
        os.makedirs(output_dir, exist_ok=True)
        
        print(f"Dataset: {dataset}")
        print(f"Output: {output_dir}")
        
        kaggle.api.dataset_download_files(
            dataset,
            path=output_dir,
            unzip=True
        )
        
        print("✅ Kaggle dataset downloaded successfully!")
        return True
        
    except ImportError:
        print("❌ Kaggle package not installed.")
        print("Install with: pip install kaggle")
        print("\nAlternatively, download manually from:")
        print("https://www.kaggle.com/datasets/nehaprabhavalkar/indian-food-101")
        return False
    
    except Exception as e:
        print(f"❌ Kaggle download failed: {e}")
        print("\nManual download instructions:")
        print("1. Go to: https://www.kaggle.com/datasets/nehaprabhavalkar/indian-food-101")
        print("2. Click 'Download' button")
        print("3. Extract the ZIP file to: ai_recipe_model/data/raw/")
        return False

def download_direct_csv():
    """
    Download Indian recipes CSV from direct sources
    """
    print("\n" + "="*60)
    print("Downloading Indian Recipes CSV")
    print("="*60)
    
    # Working alternative sources
    urls = {
        'indian_food.csv': 'https://raw.githubusercontent.com/Aditya-Dahiya/projects_presentations/main/data/indian_food.csv',
    }
    
    output_dir = "../data/raw"
    success_count = 0
    
    for filename, url in urls.items():
        filepath = os.path.join(output_dir, filename)
        if download_file(url, filepath, f"Downloading {filename}"):
            success_count += 1
    
    if success_count == 0:
        print("\n⚠️  Direct download failed. Creating extended sample dataset instead...")
        return create_extended_sample_dataset()
    
    return success_count > 0

def create_sample_dataset():
    """
    Create a small sample dataset for testing
    """
    print("\n" + "="*60)
    print("Creating Sample Dataset")
    print("="*60)
    
    import pandas as pd
    
    # Sample Indian recipes
    sample_recipes = [
        {
            'name': 'Aloo Gobi',
            'ingredients': 'potato, cauliflower, onion, tomato, turmeric, cumin, coriander, ginger, garlic, green chilli',
            'instructions': 'Heat oil, add cumin. Add onions, ginger, garlic. Add tomatoes. Add potatoes and cauliflower. Add spices. Cook until tender.',
            'cuisine': 'North Indian',
            'course': 'Main Course',
            'diet': 'Vegetarian',
            'prep_time': '15',
            'cook_time': '30'
        },
        {
            'name': 'Dal Tadka',
            'ingredients': 'toor dal, onion, tomato, turmeric, cumin, mustard seeds, curry leaves, ghee, red chilli, ginger, garlic',
            'instructions': 'Cook dal. Heat ghee, add mustard, cumin. Add onions, ginger, garlic. Add tomatoes and spices. Pour over dal.',
            'cuisine': 'North Indian',
            'course': 'Main Course',
            'diet': 'Vegetarian',
            'prep_time': '10',
            'cook_time': '25'
        },
        {
            'name': 'Paneer Butter Masala',
            'ingredients': 'paneer, butter, cream, tomato, onion, cashew, ginger, garlic, garam masala, kasuri methi, red chilli',
            'instructions': 'Make tomato gravy. Add cream and butter. Add paneer cubes. Garnish with kasuri methi.',
            'cuisine': 'North Indian',
            'course': 'Main Course',
            'diet': 'Vegetarian',
            'prep_time': '20',
            'cook_time': '30'
        },
        {
            'name': 'Chicken Biryani',
            'ingredients': 'chicken, basmati rice, onion, yogurt, tomato, ginger garlic paste, biryani masala, saffron, ghee, mint, coriander',
            'instructions': 'Marinate chicken. Cook rice. Layer rice and chicken. Dum cook.',
            'cuisine': 'Hyderabadi',
            'course': 'Main Course',
            'diet': 'Non-Vegetarian',
            'prep_time': '30',
            'cook_time': '45'
        },
        {
            'name': 'Masala Dosa',
            'ingredients': 'dosa batter, potato, onion, mustard seeds, curry leaves, turmeric, green chilli, urad dal, chana dal',
            'instructions': 'Make potato filling. Spread dosa batter on tawa. Add filling. Fold and serve.',
            'cuisine': 'South Indian',
            'course': 'Breakfast',
            'diet': 'Vegetarian',
            'prep_time': '15',
            'cook_time': '20'
        },
        {
            'name': 'Palak Paneer',
            'ingredients': 'palak, paneer, onion, tomato, cream, ginger, garlic, cumin, garam masala, kasuri methi',
            'instructions': 'Blanch spinach. Make puree. Cook onion-tomato base. Add spinach and paneer.',
            'cuisine': 'North Indian',
            'course': 'Main Course',
            'diet': 'Vegetarian',
            'prep_time': '15',
            'cook_time': '25'
        },
        {
            'name': 'Chole Bhature',
            'ingredients': 'chickpeas, onion, tomato, ginger, garlic, chole masala, tea bags, flour, yogurt, baking soda',
            'instructions': 'Cook chickpeas with spices. Make bhature dough. Deep fry bhature. Serve together.',
            'cuisine': 'Punjabi',
            'course': 'Main Course',
            'diet': 'Vegetarian',
            'prep_time': '30',
            'cook_time': '40'
        },
        {
            'name': 'Rajma Chawal',
            'ingredients': 'kidney beans, basmati rice, onion, tomato, ginger, garlic, cumin, coriander, red chilli, garam masala',
            'instructions': 'Soak and cook rajma. Make gravy. Cook rice separately. Serve together.',
            'cuisine': 'North Indian',
            'course': 'Main Course',
            'diet': 'Vegetarian',
            'prep_time': '20',
            'cook_time': '35'
        },
        {
            'name': 'Sambar',
            'ingredients': 'toor dal, drumstick, carrot, brinjal, tamarind, sambar powder, mustard seeds, curry leaves, asafoetida',
            'instructions': 'Cook dal and vegetables. Add tamarind. Add sambar powder. Temper with mustard and curry leaves.',
            'cuisine': 'South Indian',
            'course': 'Side Dish',
            'diet': 'Vegetarian',
            'prep_time': '15',
            'cook_time': '30'
        },
        {
            'name': 'Butter Chicken',
            'ingredients': 'chicken, butter, cream, tomato, onion, cashew, ginger garlic paste, garam masala, kasuri methi, red chilli',
            'instructions': 'Marinate and grill chicken. Make tomato gravy. Add butter and cream. Add chicken pieces.',
            'cuisine': 'Punjabi',
            'course': 'Main Course',
            'diet': 'Non-Vegetarian',
            'prep_time': '25',
            'cook_time': '35'
        }
    ]
    
    df = pd.DataFrame(sample_recipes)
    
    output_dir = "../data/raw"
    os.makedirs(output_dir, exist_ok=True)
    
    filepath = os.path.join(output_dir, 'sample_indian_recipes.csv')
    df.to_csv(filepath, index=False)
    
    print(f"✅ Created sample dataset: {filepath}")
    print(f"   {len(sample_recipes)} recipes")
    
    return True

def main():
    """
    Main download function
    """
    print("="*60)
    print("Indian Recipe Dataset Downloader")
    print("="*60)
    
    print("\nChoose download option:")
    print("1. Download from Kaggle (requires API key)")
    print("2. Download direct CSV files")
    print("3. Create sample dataset (10 recipes for testing)")
    print("4. All of the above")
    
    choice = input("\nEnter choice (1-4) [default: 3]: ").strip() or "3"
    
    success = False
    
    if choice == "1":
        success = download_kaggle_dataset()
    elif choice == "2":
        success = download_direct_csv()
    elif choice == "3":
        success = create_sample_dataset()
    elif choice == "4":
        success = (
            create_sample_dataset() or
            download_direct_csv() or
            download_kaggle_dataset()
        )
    else:
        print("Invalid choice!")
        return
    
    if success:
        print("\n" + "="*60)
        print("Download Complete!")
        print("="*60)
        print("\nNext steps:")
        print("1. Check downloaded files in: ai_recipe_model/data/raw/")
        print("2. Run: python preprocess_indian_recipes.py")
    else:
        print("\n" + "="*60)
        print("Download Failed or Incomplete")
        print("="*60)
        print("\nManual Download Options:")
        print("1. Kaggle: https://www.kaggle.com/datasets/nehaprabhavalkar/indian-food-101")
        print("2. GitHub: https://github.com/aakash0017/Indian-Food-Dataset")
        print("\nPlace CSV/JSON files in: ai_recipe_model/data/raw/")

if __name__ == '__main__':
    main()
