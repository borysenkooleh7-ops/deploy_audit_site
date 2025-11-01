#!/usr/bin/env sh
set -eu

echo "Applying database migrations..."
python manage.py migrate --noinput

WEB_CONCURRENCY=${WEB_CONCURRENCY:-2}
GUNICORN_TIMEOUT=${GUNICORN_TIMEOUT:-120}
GUNICORN_GRACEFUL_TIMEOUT=${GUNICORN_GRACEFUL_TIMEOUT:-120}
GUNICORN_KEEPALIVE=${GUNICORN_KEEPALIVE:-75}

echo "Starting Gunicorn on port ${PORT:-10000} with ${WEB_CONCURRENCY} sync workers..."
exec gunicorn saas_project.wsgi:application \
  --bind 0.0.0.0:${PORT:-10000} \
  --workers ${WEB_CONCURRENCY} \
  --worker-class sync \
  --timeout ${GUNICORN_TIMEOUT} \
  --graceful-timeout ${GUNICORN_GRACEFUL_TIMEOUT} \
  --keep-alive ${GUNICORN_KEEPALIVE} \
  --access-logfile - \
  --error-logfile - \
  --log-level info


