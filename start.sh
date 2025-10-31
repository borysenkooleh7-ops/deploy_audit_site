#!/usr/bin/env sh
set -eu

echo "Applying database migrations..."
python manage.py migrate --noinput

# Optionally re-collect static in case env differs; ignore failure
echo "Collecting static files (optional)..."
python manage.py collectstatic --no-input --clear || true

echo "Starting Gunicorn..."
exec gunicorn saas_project.wsgi:application --bind 0.0.0.0:${PORT:-10000} --workers 2 --threads 4 --timeout 120


