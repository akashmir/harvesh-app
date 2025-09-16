#!/usr/bin/env python3
"""
Fix all APIs by adding proper import path handling
"""

import os
import re

# List of all API files
API_FILES = [
    'src/api/crop_api_production.py',
    'src/api/weather_integration_api.py',
    'src/api/market_price_api.py',
    'src/api/yield_prediction_api.py',
    'src/api/field_management_api.py',
    'src/api/satellite_soil_api.py',
    'src/api/multilingual_ai_api.py',
    'src/api/ai_disease_detection_api.py',
    'src/api/sustainability_scoring_api.py',
    'src/api/crop_rotation_api.py',
    'src/api/offline_capability_api.py',
    'src/api/sih_2025_integrated_api.py'
]

def fix_api_imports(file_path):
    """Fix import issues in an API file"""
    print(f"🔧 Fixing {file_path}...")
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Check if already fixed
        if 'sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))' in content:
            print(f"✅ {file_path} - Already fixed")
            return True
        
        # Add path fix after existing imports
        lines = content.split('\n')
        new_lines = []
        imports_added = False
        
        for i, line in enumerate(lines):
            new_lines.append(line)
            
            # Add path fix after the last import statement
            if line.strip().startswith('import ') or line.strip().startswith('from '):
                # Check if next line is not an import
                if i + 1 < len(lines) and not (lines[i + 1].strip().startswith('import ') or lines[i + 1].strip().startswith('from ')):
                    if not imports_added:
                        new_lines.append('')
                        new_lines.append('# Fix import paths for direct execution')
                        new_lines.append('import sys')
                        new_lines.append('import os')
                        new_lines.append('sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))')
                        new_lines.append('')
                        imports_added = True
        
        # Write the fixed content
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(new_lines))
        
        print(f"✅ {file_path} - Fixed successfully")
        return True
        
    except Exception as e:
        print(f"❌ {file_path} - Error: {e}")
        return False

def main():
    """Fix all API files"""
    print("🔧 Fixing all API import issues...")
    print("=" * 50)
    
    fixed_count = 0
    for api_file in API_FILES:
        if os.path.exists(api_file):
            if fix_api_imports(api_file):
                fixed_count += 1
        else:
            print(f"⚠️ {api_file} - File not found")
    
    print(f"\n📊 SUMMARY:")
    print(f"✅ Fixed: {fixed_count}/{len(API_FILES)} APIs")
    print(f"🎉 All APIs should now work when run directly!")

if __name__ == "__main__":
    main()
