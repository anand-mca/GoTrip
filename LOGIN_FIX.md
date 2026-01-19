# 🔐 Login Error - Complete Fix Guide

## Step 1: Fix Supabase Configuration

### 1.1 Configure CORS in Supabase Dashboard

Go to: https://supabase.com/dashboard/project/tkkjcsuzdtiytrwipyrw/settings/api

**Step A: Set Site URL**
- Find "Site URL"
- Set to: `http://localhost`
- Click Save

**Step B: Add Redirect URLs**
- Find "Additional Redirect URLs"
- Add these URLs (one per line):
```
http://localhost:*
http://localhost:3000
http://localhost:8080
http://localhost:54321
```
- Click Save

### 1.2 Check Email Provider

Go to: https://supabase.com/dashboard/project/tkkjcsuzdtiytrwipyrw/auth/providers

- Make sure **Email** provider is **ENABLED** (should have a green toggle)
- If not enabled, enable it now

---

## Step 2: Set Up Database Tables & RLS

### 2.1 Open SQL Editor

Go to: https://supabase.com/dashboard/project/tkkjcsuzdtiytrwipyrw/sql/new

### 2.2 Run This SQL

Copy and paste this entire SQL script:

```sql
-- 1. Create profiles table
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL PRIMARY KEY,
  name TEXT,
  email TEXT,
  phone TEXT,
  bio TEXT,
  profile_image TEXT,
  saved_trips TEXT[],
  booked_trips TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Enable RLS on profiles table
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 3. Create RLS policies for profiles
DROP POLICY IF EXISTS "Users can read own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can create own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;

CREATE POLICY "Users can read own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can create own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- 4. Enable public read access to destinations
ALTER TABLE public.destinations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read access" ON public.destinations;

CREATE POLICY "Allow public read access" ON public.destinations
  FOR SELECT USING (true);

-- 5. Verify tables
SELECT COUNT(*) as profiles FROM public.profiles;
SELECT COUNT(*) as destinations FROM public.destinations;
```

Click **Run** and wait for success.

---

## Step 3: Test Login

### 3.1 Create a New Account (Sign Up)

1. Open your Flutter app: http://localhost:YOUR_PORT
2. Click **"Create Account"** button
3. Fill in:
   - **Name**: John Doe
   - **Email**: test@example.com
   - **Password**: Test@1234
4. Click **"Sign Up"**
5. You should see success message

### 3.2 Login with New Account

1. Click **"Login"** button
2. Enter:
   - **Email**: test@example.com
   - **Password**: Test@1234
3. Click **"Login"**
4. Should navigate to Home screen ✅

### 3.3 Or Use Admin Account

Try the hardcoded admin account:
- **Email**: admin@gmail.com
- **Password**: admin123

---

## Step 4: Troubleshooting

### ❌ "Failed to fetch" Error

**Cause**: CORS not configured

**Solution**:
1. Go to Supabase Settings → API
2. Check "Site URL" is set to `http://localhost`
3. Check "Additional Redirect URLs" includes `http://localhost:*`
4. Restart Flutter app

### ❌ "Invalid login credentials"

**Causes**:
1. Account doesn't exist (create new account first)
2. Email/password wrong
3. Email provider not enabled

**Solution**:
1. Go to Supabase Auth → Providers → Check Email is enabled
2. Try Sign Up first, then Login
3. Use correct email/password

### ❌ "profiles table does not exist"

**Cause**: Database tables not created

**Solution**:
1. Run the SQL script from Step 2 above
2. Verify tables exist in Table Editor

### ❌ "You do not have permission to access this table"

**Cause**: RLS policies wrong

**Solution**:
1. Run the SQL script from Step 2 (it fixes RLS)
2. Make sure all policies are created

### ❌ "Connection error" on web

**Cause**: CORS or network issue

**Solution**:
1. Check browser console (F12 → Console tab)
2. Look for specific error
3. If CORS: Fix Step 1
4. If timeout: Check internet connection

---

## Step 5: Quick Verification Checklist

Before testing login, verify:

- [ ] Supabase dashboard accessible
- [ ] Email provider enabled
- [ ] Site URL set to `http://localhost`
- [ ] Redirect URLs added
- [ ] profiles table exists in Table Editor
- [ ] profiles table has RLS enabled
- [ ] RLS policies created
- [ ] Flutter app running on http://localhost:PORT
- [ ] Browser console (F12) has no red errors

---

## Step 6: Expected Behavior

### Sign Up Flow:
1. User enters name, email, password
2. Click "Sign Up"
3. Loading spinner appears
4. Success: "Account created! Please log in"
5. Navigate to Login screen

### Login Flow:
1. User enters email, password
2. Click "Login"
3. Loading spinner appears
4. Success: Navigate to Home screen
5. See "Explore", "Plan Trip", "Profile" tabs

---

## Emergency Reset

If nothing works, try these commands:

### In Supabase SQL Editor:

```sql
-- Delete and recreate profiles table
DROP TABLE IF EXISTS public.profiles CASCADE;

CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT DEFAULT '',
  bio TEXT DEFAULT '',
  profile_image TEXT DEFAULT '',
  saved_trips TEXT[] DEFAULT '{}',
  booked_trips TEXT[] DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable all for authenticated users" ON public.profiles
  FOR ALL USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- Delete all existing users and start fresh (CAREFUL!)
-- DELETE FROM auth.users;
```

Then restart the app.

---

## Need More Help?

1. **Screenshot**: Take a screenshot of the exact error
2. **Console log**: Press F12 → Console → Copy any red errors
3. **Check Supabase logs**: Dashboard → Logs tab
4. **Verify credentials**: Make sure SUPABASE_URL and SUPABASE_ANON_KEY are correct

The app should work once all these steps are done! 🚀
