# 🚀 QUICK START: Insert 476 New Destinations

## 30-Second Setup

### 1️⃣ Set API Key (Choose Your OS)

**Windows PowerShell:**
```powershell
$env:SUPABASE_KEY = "paste-your-key-here"
```

**Windows CMD:**
```cmd
set SUPABASE_KEY=paste-your-key-here
```

**Mac/Linux:**
```bash
export SUPABASE_KEY="paste-your-key-here"
```

### 2️⃣ Run Insertion Script

```bash
python INSERT_DESTINATIONS_BULK.py
```

### 3️⃣ Done! 🎉

Expected output: `🎉 All destinations inserted successfully!`

---

## Where to Get Your API Key

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your **GoTrip** project
3. Click **Settings** → **API**
4. Copy the **Service Role Key** (or anon key if preferred)
5. Paste it above as `paste-your-key-here`

---

## What Gets Inserted

✅ **476 destinations** from:
- Kerala (Kochi, Munnar, Alappuzha, etc.)
- Tamil Nadu (Chennai, Ooty, Madurai, etc.)
- Karnataka (Bangalore, Mysore, Hampi, etc.)
- Rajasthan (Jaipur, Udaipur, Jodhpur, etc.)
- Maharashtra (Mumbai, Goa, Aurangabad, etc.)
- North/North-East India (Delhi, Varanasi, Kolkata, etc.)

---

## Verify Success

```sql
-- Check total destinations
SELECT COUNT(*) FROM destinations;

-- Should show significant increase from before
```

---

## Still Need Help?

📖 Read: [CSV_TO_SUPABASE_GUIDE.md](CSV_TO_SUPABASE_GUIDE.md)
