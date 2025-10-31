#!/usr/bin/env sh
set -eu

echo "Applying database migrations..."
python manage.py migrate --noinput

echo "Starting Gunicorn on port ${PORT:-10000}..."
exec gunicorn saas_project.wsgi:application --bind 0.0.0.0:${PORT:-10000} --workers 2 --threads 4 --timeout 120


