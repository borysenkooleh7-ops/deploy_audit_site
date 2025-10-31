# Render.com Deployment Guide for Sistema Audita

## Overview
This guide explains how to deploy your Django application to Render.com. All necessary configuration files have been created.

## What Was Fixed

### 1. Missing Dependencies
Added to `requirements.txt`:
- `gunicorn==21.2.0` - Production WSGI server required by Render
- `whitenoise==6.6.0` - Static file serving (was configured but missing)
- `psycopg2-binary==2.9.9` - PostgreSQL database adapter
- `dj-database-url==2.1.0` - Database URL parser for Render's DATABASE_URL

### 2. System Dependencies Issue (PyGObject & pycairo)
**Problem**: PyGObject and pycairo require system libraries not available by default on Render.

**Solution**: Created `build.sh` script that installs:
- libgirepository1.0-dev
- libcairo2-dev
- libpango1.0-dev
- pkg-config
- python3-dev
- And other required libraries

### 3. Database Configuration
Updated `saas_project/settings.py` to support Render's `DATABASE_URL` environment variable while maintaining backward compatibility with individual DB environment variables.

### 4. Deployment Configuration
Created `render.yaml` with:
- Web service configuration
- PostgreSQL database setup
- Environment variable definitions
- Build and start commands

## Deployment Steps

### Step 1: Push Changes to GitHub

```bash
# Make build.sh executable
git update-index --chmod=+x build.sh

# Stage all changes
git add .

# Commit changes
git commit -m "Configure deployment for Render.com

- Add production dependencies (gunicorn, whitenoise, psycopg2)
- Create build.sh for system dependencies installation
- Create render.yaml for Render configuration
- Update settings.py to support DATABASE_URL
- Add .env files to .gitignore for security"

# Push to GitHub
git push origin main
```

### Step 2: Configure Render.com

1. **Log in to Render Dashboard**: https://dashboard.render.com/

2. **Create New PostgreSQL Database** (if using render.yaml, this will be automatic):
   - Click "New +"
   - Select "PostgreSQL"
   - Name: `sistema-audita-db`
   - Plan: Free (or your preferred plan)
   - Click "Create Database"

3. **Create Web Service**:
   - Click "New +"
   - Select "Web Service"
   - Connect your GitHub repository: `borysenkooleh7-ops/deploy_audit_site`
   - Render will detect `render.yaml` automatically

4. **Configure Environment Variables** (if not using render.yaml):

   Go to your web service settings and add:

   **Required Variables:**
   ```
   PYTHON_VERSION=3.13.4
   DEBUG=false
   SECRET_KEY=[generate a secure key - Render can auto-generate]
   DATABASE_URL=[auto-populated from PostgreSQL database]
   ```

   **Your Application Variables:**
   ```
   ALLOWED_HOSTS=your-app-name.onrender.com
   CSRF_TRUSTED_ORIGINS=https://your-app-name.onrender.com
   BASE_URL=https://your-app-name.onrender.com
   DJANGO_SECURE_SSL_REDIRECT=true
   EMAIL_HOST_USER=your-email@gmail.com
   EMAIL_HOST_PASSWORD=your-app-password
   ```

### Step 3: Deploy

1. Click "Deploy" button in Render dashboard
2. Render will:
   - Clone your repository
   - Run `build.sh` (installs system dependencies)
   - Install Python dependencies from `requirements.txt`
   - Run `collectstatic` to gather static files
   - Run `migrate` to set up database
   - Start your app with `gunicorn`

### Step 4: Monitor Build

Watch the build logs in Render dashboard. Look for:
- ✅ System dependencies installed
- ✅ Python packages installed (including PyGObject and pycairo)
- ✅ Collectstatic completed
- ✅ Migrations applied
- ✅ Server started

## Important Notes

### Database Migration
Your local `db.sqlite3` contains development data. To migrate to production PostgreSQL:

1. **Export data from SQLite**:
   ```bash
   python manage.py dumpdata --natural-foreign --natural-primary -e contenttypes -e auth.Permission --indent 4 > datadump.json
   ```

2. **Load into PostgreSQL** (after deployment):
   ```bash
   # SSH into Render or use Render Shell
   python manage.py loaddata datadump.json
   ```

### Security Checklist
- ✅ `.env` and `.env.local` are in `.gitignore`
- ✅ `DEBUG=false` in production
- ✅ Secure `SECRET_KEY` generated
- ✅ SSL redirect enabled
- ✅ CSRF protection configured
- ⚠️ **Never commit `.env` files to Git**

### Static Files
- WhiteNoise is configured to serve static files
- `collectstatic` runs during build
- Compressed and hashed files stored in `staticfiles/`

### Email Configuration
Update environment variables with your SMTP credentials:
- For Gmail: Use App Passwords (not your regular password)
- Enable 2FA on Gmail account
- Generate App Password at: https://myaccount.google.com/apppasswords

### Build Time
First deployment may take 5-10 minutes due to:
- Installing system dependencies
- Compiling PyGObject and pycairo
- Collecting static files

Subsequent deploys will be faster (2-3 minutes).

## Troubleshooting

### Build Fails on PyGObject
If you see: `ERROR: Dependency 'gobject-introspection-1.0' is required but not found`

**Solution**: Ensure `build.sh` is executable:
```bash
chmod +x build.sh
git add build.sh
git commit -m "Make build.sh executable"
git push
```

### Database Connection Error
Check:
1. PostgreSQL database is created in Render
2. `DATABASE_URL` environment variable is set
3. `psycopg2-binary` is in requirements.txt

### Static Files Not Loading
Check:
1. `collectstatic` ran successfully in build logs
2. `ALLOWED_HOSTS` includes your Render domain
3. `CSRF_TRUSTED_ORIGINS` includes your Render domain with `https://`

### Application Error on Start
Check logs in Render dashboard:
```
Logs > View Logs
```

Common issues:
- Missing environment variables
- Database migration errors
- Import errors (missing dependencies)

## render.yaml Configuration

The `render.yaml` file configures:

```yaml
services:
  - type: web
    name: sistema-audita
    runtime: python
    plan: free
    buildCommand: ./build.sh
    startCommand: gunicorn saas_project.wsgi:application
    envVars: [environment variable definitions]

databases:
  - name: sistema-audita-db
    databaseName: sistema_audita_db
    user: sistema_audita_user
    plan: free
```

## Manual Build Commands (if not using build.sh)

If you prefer manual configuration in Render:

**Build Command:**
```bash
pip install -r requirements.txt && python manage.py collectstatic --no-input && python manage.py migrate
```

**Start Command:**
```bash
gunicorn saas_project.wsgi:application
```

**Note**: This won't install system dependencies for PyGObject/pycairo. Use `build.sh` instead.

## Cost Estimate

**Free Tier (recommended for testing):**
- Web Service: Free (spins down after 15 min of inactivity)
- PostgreSQL: Free (90 days, then $7/month)

**Paid Tier:**
- Starter Web Service: $7/month (always on)
- PostgreSQL: $7/month (1GB storage)

## Support

If deployment fails:
1. Check Render build logs for errors
2. Verify all environment variables are set
3. Ensure `build.sh` is executable
4. Check GitHub repository is connected correctly

## Next Steps After Deployment

1. **Create Superuser**:
   ```bash
   # In Render Shell
   python manage.py createsuperuser
   ```

2. **Test Application**:
   - Visit your Render URL
   - Test login/registration
   - Test PDF generation (WeasyPrint)
   - Verify email sending

3. **Custom Domain** (optional):
   - Configure in Render dashboard
   - Update `ALLOWED_HOSTS` and `CSRF_TRUSTED_ORIGINS`
   - Update DNS records

4. **Monitoring**:
   - Enable health checks in Render
   - Set up error monitoring (Sentry, etc.)
   - Configure backup schedule for database

## Files Created/Modified

- ✅ `requirements.txt` - Added production dependencies
- ✅ `build.sh` - System dependencies installation script
- ✅ `render.yaml` - Render deployment configuration
- ✅ `saas_project/settings.py` - Database URL support
- ✅ `.gitignore` - Added .env files
- ✅ `RENDER_DEPLOYMENT_GUIDE.md` - This guide

## Ready to Deploy!

Your application is now configured for Render.com deployment. Follow the steps above to deploy.

**Quick Start:**
```bash
git add .
git commit -m "Configure for Render deployment"
git push origin main
```

Then go to Render dashboard and create a new web service from your GitHub repository.
