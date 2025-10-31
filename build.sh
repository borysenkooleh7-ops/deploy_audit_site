#!/usr/bin/env bash
# exit on error
set -o errexit

echo "Installing system dependencies for PyGObject and pycairo..."

# Install system dependencies required for PyGObject, pycairo, and weasyprint
apt-get update
apt-get install -y \
    libgirepository1.0-dev \
    libcairo2-dev \
    pkg-config \
    python3-dev \
    gir1.2-gtk-3.0 \
    libpango1.0-dev \
    libpangocairo-1.0-0 \
    libgdk-pixbuf2.0-dev \
    libffi-dev \
    shared-mime-info

echo "Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

echo "Running Django collectstatic..."
python manage.py collectstatic --no-input

echo "Running Django migrations..."
python manage.py migrate

echo "Build completed successfully!"
