#!/usr/bin/env python3
"""
Script to create a clean version of the Harvest Enterprise App repository
by excluding large files and keeping only essential code and documentation.
"""

import os
import shutil
import subprocess
from pathlib import Path

def create_clean_repository():
    """Create a clean version of the repository without large files."""
    
    # Define the source and destination directories
    source_dir = Path(".")
    clean_dir = Path("../harvest-enterprise-app-clean")
    
    # Create clean directory
    if clean_dir.exists():
        shutil.rmtree(clean_dir)
    clean_dir.mkdir(parents=True)
    
    # Files and directories to exclude
    exclude_patterns = [
        "backend/simple_multi_dataset/",
        "backend/runs/",
        "backend/*.pt",
        "backend/*.db",
        "backend/test_*.jpg",
        "backend/test_*.png",
        "venv311/",
        "venv/",
        "__pycache__/",
        "*.pyc",
        ".git/",
        "node_modules/",
        "build/",
        "dist/",
        ".dart_tool/",
        "frontend/build/",
        "frontend/.dart_tool/",
        "frontend/.packages",
        "frontend/.pub-cache/",
        "frontend/.pub/",
        "frontend/flutter_*.png",
        "frontend/linked_*.ds",
        "frontend/unlinked.ds",
        "frontend/unlinked_spec.ds",
        "frontend/android/app/debug/",
        "frontend/android/app/profile/",
        "frontend/android/app/release/",
        "frontend/ios/Flutter/App.framework/",
        "frontend/ios/Flutter/Flutter.framework/",
        "frontend/ios/Flutter/Flutter.podspec",
        "frontend/ios/Flutter/Generated.xcconfig",
        "frontend/ios/Flutter/app.flx",
        "frontend/ios/Flutter/app.zip",
        "frontend/ios/Flutter/flutter_assets/",
        "frontend/ios/Flutter/flutter_export_environment.sh",
        "frontend/ios/ServiceDefinitions.json",
        "frontend/ios/Runner/GeneratedPluginRegistrant.*",
        "frontend/web/",
        "*.log",
        "logs/",
        ".env",
        ".env.local",
        ".env.production",
        ".env.staging",
        "*.tmp",
        "*.temp",
        "temp/",
        "tmp/",
        "*.tar.gz",
        "*.zip",
        "*.rar",
        "*.7z",
        "*.bak",
        "*.backup",
        "*.old",
        ".DS_Store",
        "Thumbs.db",
        "*.cover",
        ".coverage",
        ".coverage.*",
        "coverage.xml",
        ".hypothesis/",
        ".pytest_cache/",
        ".ipynb_checkpoints/",
        ".python-version",
        "Pipfile.lock",
        "__pypackages__/",
        ".spyderproject",
        ".spyproject",
        ".ropeproject",
        "/site",
        ".mypy_cache/",
        ".dmypy.json",
        "dmypy.json",
        ".pyre/",
        "docs/_build/",
        "htmlcov/",
    ]
    
    def should_exclude(file_path):
        """Check if a file should be excluded based on patterns."""
        file_str = str(file_path)
        for pattern in exclude_patterns:
            if pattern.endswith("/"):
                if file_str.startswith(pattern):
                    return True
            elif pattern.startswith("*"):
                if file_str.endswith(pattern[1:]):
                    return True
            elif pattern in file_str:
                return True
        return False
    
    def copy_tree(src, dst):
        """Recursively copy directory tree, excluding specified patterns."""
        if src.is_file():
            if not should_exclude(src):
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src, dst)
        elif src.is_dir():
            if not should_exclude(src):
                dst.mkdir(parents=True, exist_ok=True)
                for item in src.iterdir():
                    copy_tree(item, dst / item.name)
    
    print("Creating clean repository...")
    copy_tree(source_dir, clean_dir)
    
    # Create a new .gitignore for the clean repo
    gitignore_content = """# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# Virtual environments
venv/
venv311/
env/
ENV/
env.bak/
venv.bak/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Flutter
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
build/
flutter_*.png
linked_*.ds
unlinked.ds
unlinked_spec.ds

# Android
android/app/debug
android/app/profile
android/app/release

# iOS
ios/Flutter/App.framework
ios/Flutter/Flutter.framework
ios/Flutter/Flutter.podspec
ios/Flutter/Generated.xcconfig
ios/Flutter/app.flx
ios/Flutter/app.zip
ios/Flutter/flutter_assets/
ios/Flutter/flutter_export_environment.sh
ios/ServiceDefinitions.json
ios/Runner/GeneratedPluginRegistrant.*

# Web
web/

# Database files
*.db
*.sqlite
*.sqlite3

# Large ML datasets and models
backend/simple_multi_dataset/
backend/*.pt
backend/*.pth
backend/*.h5
backend/*.pkl
backend/*.joblib
backend/models/
backend/trained_models/
backend/datasets/
backend/data/images/
backend/data/labels/

# Log files
*.log
logs/

# Environment files
.env
.env.local
.env.production
.env.staging

# Temporary files
*.tmp
*.temp
temp/
tmp/

# Large files that cause push issues
backend/yolov8n.pt
backend/sih_2025_integrated.db
backend/simple_yolov8_disease_detection.db

# Test images
*.jpg
*.jpeg
*.png
*.gif
*.bmp
*.tiff
!frontend/assets/images/*.png
!frontend/assets/images/*.jpg

# Documentation build
docs/_build/

# Coverage reports
htmlcov/
.coverage
.coverage.*
coverage.xml
*.cover
.hypothesis/
.pytest_cache/

# Jupyter Notebook
.ipynb_checkpoints

# pyenv
.python-version

# pipenv
Pipfile.lock

# SageMath parsed files
*.sage.py

# Spyder project settings
.spyderproject
.spyproject

# Rope project settings
.ropeproject

# mkdocs documentation
/site

# mypy
.mypy_cache/
.dmypy.json
dmypy.json

# Pyre type checker
.pyre/

# Node modules (if any)
node_modules/

# Large deployment files
*.tar.gz
*.zip
*.rar
*.7z

# Backup files
*.bak
*.backup
*.old

# System files
.DS_Store
Thumbs.db
"""
    
    with open(clean_dir / ".gitignore", "w") as f:
        f.write(gitignore_content)
    
    print(f"Clean repository created at: {clean_dir}")
    print("Repository size reduced by excluding large files and datasets.")
    print("\nNext steps:")
    print(f"1. cd {clean_dir}")
    print("2. git init")
    print("3. git add .")
    print("4. git commit -m 'Initial commit: Clean Harvest Enterprise App'")
    print("5. git remote add origin https://github.com/akashmir/harvesh2.git")
    print("6. git push -u origin master")

if __name__ == "__main__":
    create_clean_repository()
