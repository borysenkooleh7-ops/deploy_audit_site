# 🚨 URGENT FIX - Render is Using Wrong Runtime

## Problem
Your Render service is **still using Python native runtime** instead of Docker runtime. The render.yaml file has `runtime: docker` but Render ignores it because the service was already created with Python runtime.

## Evidence from Build Logs
```
==> Installing Python version 3.13.4...
==> Running build command 'pip install -r requirements.txt...'
```

If it were using Docker, you would see:
```
==> Building Docker image...
==> Step 1/8: FROM python:3.13.4-slim
```

## Solution: Delete and Recreate Service

### Step 1: Delete Existing Service
1. Go to https://dashboard.render.com/
2. Find your `sistema-audita` web service
3. Click on the service
4. Go to **Settings** (bottom of left sidebar)
5. Scroll to the very bottom
6. Click **"Delete Web Service"**
7. Type the service name to confirm
8. Delete it

### Step 2: Create New Service from Blueprint
1. In Render dashboard, click **"New +"**
2. Select **"Blueprint"**
3. Connect your repository: `borysenkooleh7-ops/deploy_audit_site`
4. Render will detect `render.yaml` automatically
5. Click **"Apply"**

**IMPORTANT**: When creating from Blueprint, Render will:
- ✅ Use `runtime: docker` from render.yaml
- ✅ Build using your Dockerfile
- ✅ Install all system dependencies (gobject-introspection, etc.)
- ✅ Create PostgreSQL database automatically

### Step 3: Set Required Environment Variables

After service is created, add these in the Render dashboard:

**Required Variables:**
```
ALLOWED_HOSTS=your-new-app-name.onrender.com
CSRF_TRUSTED_ORIGINS=https://your-new-app-name.onrender.com
BASE_URL=https://your-new-app-name.onrender.com
EMAIL_HOST_USER=your-gmail@gmail.com
EMAIL_HOST_PASSWORD=your-gmail-app-password
```

**Auto-configured by render.yaml:**
- `DEBUG=false` ✅
- `SECRET_KEY` (auto-generated) ✅
- `DATABASE_URL` (from database) ✅
- `DJANGO_SECURE_SSL_REDIRECT=true` ✅

### Step 4: Deploy
Once the service is created, it will automatically start deploying. Watch the build logs and you should see:

```
==> Building Docker image...
==> Step 1/8: FROM python:3.13.4-slim
==> Step 2/8: RUN apt-get update && apt-get install...
     Installing gobject-introspection ← This is the fix!
==> Step 3/8: RUN pip install -r requirements.txt
     Successfully installed PyGObject-3.50.0 ← Will work now!
```

---

## Alternative: Manual Runtime Change (May Not Work)

If you don't want to delete the service, try this:

1. Go to your service in Render dashboard
2. Click **"Settings"** in left sidebar
3. Look for **"Runtime"** or **"Build Settings"**
4. Try to change from "Python" to "Docker"
5. Save and redeploy

**NOTE**: This option may not be available in Render's UI. If you can't find it, you MUST delete and recreate.

---

## Why This Happened

1. You created the service BEFORE the render.yaml existed
2. Render remembered the service configuration (Python runtime)
3. Even though you pushed render.yaml with `runtime: docker`, Render doesn't automatically migrate existing services
4. The service continues using Python runtime, which cannot install gobject-introspection

---

## What You'll See When It Works

**Correct Docker build output:**
```
==> Checking out commit 94016b1...
==> Building Docker image...
==> [1/8] FROM python:3.13.4-slim
==> [2/8] RUN apt-get update && apt-get install -y...
     Get:1 http://deb.debian.org/debian bookworm InRelease
     Get:2 http://deb.debian.org/debian bookworm-updates InRelease
     ...
     Setting up gobject-introspection (1.74.0-3) ...
     Setting up libgirepository1.0-dev (1.74.0-3) ...
==> [3/8] COPY requirements.txt .
==> [4/8] RUN pip install --upgrade pip && pip install -r requirements.txt
     Collecting PyGObject==3.50.0
     Building wheel for pygobject...
     Successfully built pygobject
     Successfully installed PyGObject-3.50.0
==> [5/8] COPY . .
==> [6/8] RUN python manage.py collectstatic...
     120 static files copied to '/app/staticfiles'
==> [7/8] RUN useradd -m -u 1000 appuser...
==> [8/8] USER appuser
==> Successfully built image
==> Starting web service...
     [INFO] Starting gunicorn 21.2.0
     [INFO] Listening at: http://0.0.0.0:10000
     [INFO] Using worker class: sync
     [INFO] Booting worker with pid: 123
```

---

## Time Estimate

- Delete old service: 1 minute
- Create new service from Blueprint: 2 minutes
- Docker build (first time): 10-15 minutes
- Total: ~20 minutes

---

## Next Steps After Successful Deployment

1. Get your new Render URL (will be shown after deployment)
2. Update environment variables with the correct domain
3. Create superuser:
   ```bash
   # In Render Shell
   python manage.py createsuperuser
   ```
4. Test your application
5. Verify PDF generation works (WeasyPrint)

---

## If You Still Get Errors

If after recreating you STILL see Python runtime being used:

1. Check that your repository has the latest commit (94016b1)
2. Verify Dockerfile exists in your repo: https://github.com/borysenkooleh7-ops/deploy_audit_site/blob/main/Dockerfile
3. Verify render.yaml exists: https://github.com/borysenkooleh7-ops/deploy_audit_site/blob/main/render.yaml
4. Check render.yaml line 4 says `runtime: docker`

**If Dockerfile or render.yaml are missing from GitHub:**
```bash
git add Dockerfile render.yaml
git commit -m "Ensure Docker deployment files are tracked"
git push origin main
```

Then delete and recreate the Render service.
