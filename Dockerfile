FROM python:3.13.4-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=10000

# Install system dependencies required for PyGObject, pycairo, and WeasyPrint
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Build tools
    build-essential \
    pkg-config \
    # Python development
    python3-dev \
    # Cairo and Pango for PDF generation
    libcairo2 \
    libcairo2-dev \
    libpango-1.0-0 \
    libpango1.0-dev \
    libpangocairo-1.0-0 \
    # GObject Introspection (critical for PyGObject)
    gobject-introspection \
    libgirepository1.0-dev \
    gir1.2-gtk-3.0 \
    # Additional dependencies
    libgdk-pixbuf-2.0-0 \
    libgdk-pixbuf2.0-dev \
    libffi-dev \
    libglib2.0-dev \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    shared-mime-info \
    # PostgreSQL client (for database)
    libpq-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements file
COPY requirements.txt .

# Upgrade pip and install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy project files
COPY . .

# Collect static files (will be served by whitenoise)
RUN python manage.py collectstatic --no-input --clear || echo "Collectstatic failed, continuing..."

# Create non-root user for security
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app
USER appuser

# Expose port (Render uses PORT environment variable)
EXPOSE $PORT

# Start command using gunicorn
CMD gunicorn saas_project.wsgi:application --bind 0.0.0.0:$PORT --workers 2 --threads 4 --timeout 120
