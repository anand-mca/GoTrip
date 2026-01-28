# CSV to Supabase: New Destinations Insertion Guide

## 📋 Overview

You have **476 new destination records** from the file `datasets/new_dataset.csv` ready to be inserted into your Supabase `destinations` table. This guide provides step-by-step instructions for getting all these records into your database.

---

## 📊 Dataset Statistics

| Metric | Value |
|--------|-------|
| **Total Records** | 476 |
| **States Covered** | 16 states + 1 UT |
| **Major Cities** | 60+ |
| **Primary Regions** | Kerala, Tamil Nadu, Karnataka, Rajasthan, Maharashtra |
| **Categories** | beach, history, nature, shopping, religious, cultural, adventure, food |

### States & Distribution

- **Kerala**: Kochi, Munnar, Alappuzha, Wayanad, Varkala
- **Tamil Nadu**: Chennai, Ooty, Madurai, Kanyakumari, Rameshwaram, Coimbatore, Thanjavur
- **Karnataka**: Bangalore, Mysore, Coorg, Hampi, Gokarna, Chikmagalur
- **Rajasthan**: Jaipur, Udaipur, Jaisalmer, Jodhpur, Pushkar
- **Maharashtra**: Mumbai, Aurangabad, Nasik, Mahabaleshwar, Lonavala, Nagpur
- **North India**: Delhi, Agra, Varanasi, Amritsar, Shimla, Manali, Dharamshala, etc.
- **Northeast**: Kolkata, Darjeeling
- **Islands**: Goa, Leh (Ladakh), Srinagar (J&K)
- **Other**: Patna (Bihar), Ranchi (Jharkhand), Bhubaneswar & Puri (Odisha)

---

## 🚀 Quick Start (Recommended)

### Method 1: Python Script (Fastest & Safest)

This is the **recommended approach** as it handles errors gracefully and avoids duplicates.

#### Prerequisites

```bash
pip install supabase
```

#### Set Environment Variables

**On Windows (PowerShell):**
```powershell
$env:SUPABASE_URL = "https://xkwkftxbjqhuaodtpfzf.supabase.co"
$env:SUPABASE_KEY = "your-supabase-api-key-here"
```

**On Windows (Command Prompt):**
```cmd
set SUPABASE_URL=https://xkwkftxbjqhuaodtpfzf.supabase.co
set SUPABASE_KEY=your-supabase-api-key-here
```

**On macOS/Linux:**
```bash
export SUPABASE_URL="https://xkwkftxbjqhuaodtpfzf.supabase.co"
export SUPABASE_KEY="your-supabase-api-key-here"
```

#### Run the Script

```bash
python INSERT_DESTINATIONS_BULK.py
```

Or with a custom CSV path:
```bash
python INSERT_DESTINATIONS_BULK.py path/to/your/file.csv
```

#### Expected Output

```
📂 Reading destinations from: datasets/new_dataset.csv

✅ Parsed 476 destinations from CSV

📤 Inserting 476 destinations into Supabase...
✅ Batch 1: Inserted 50 records
✅ Batch 2: Inserted 50 records
...
✅ Batch 10: Inserted 26 records

==================================================
📊 INSERTION SUMMARY
==================================================
Total destinations processed: 476
Total successfully inserted: 476
Failed batches: 0

🎉 All destinations inserted successfully!
```

---

## Alternative Methods

### Method 2: SQL File (Direct Database)

Use the provided `INSERT_NEW_DESTINATIONS.sql` file:

1. Open Supabase Dashboard
2. Go to **SQL Editor**
3. Create a new query
4. Paste the content from `INSERT_NEW_DESTINATIONS.sql`
5. Click **Run**

**Note**: The SQL file contains a basic structure. For 476 records, the Python script is preferred.

### Method 3: Supabase Dashboard (Manual - Not Recommended)

For small datasets only:
1. Go to Supabase Dashboard → Destinations Table
2. Click **Insert** → **New Row**
3. Fill in the fields manually

⚠️ **Warning**: This would require 476 manual entries!

---

## 📁 File Descriptions

| File | Purpose |
|------|---------|
| `datasets/new_dataset.csv` | Source data with 476 destination records |
| `INSERT_DESTINATIONS_BULK.py` | **Recommended** Python script for bulk insertion |
| `INSERT_NEW_DESTINATIONS.sql` | SQL template (reference only) |

---

## 🔧 How the Python Script Works

### Step 1: Data Parsing
```
CSV Row → Dictionary with type conversion
- Float fields: latitude, longitude, rating, cost_per_day
- Integer fields: visit_duration_hours, entry_fee
- JSON arrays: categories, tags, facilities
- Booleans: is_active
```

### Step 2: Duplicate Check
```
- Extracts all IDs from the batch
- Checks if they already exist in the database
- Only inserts new records
```

### Step 3: Batch Insertion
```
- Batches of 50 records to prevent timeouts
- 476 records = 10 batches (9×50 + 1×26)
- Real-time progress feedback
```

### Step 4: Error Handling
```
- Captures and logs parsing errors
- Reports failed batches
- Provides detailed summary
```

---

## 📋 CSV Column Reference

| Column | Type | Example | Notes |
|--------|------|---------|-------|
| `id` | string | `kl_koc_001` | Unique identifier (state_city_number) |
| `name` | string | `Fort Kochi Beach` | Destination name |
| `city` | string | `Kochi` | City name |
| `state` | string | `Kerala` | State/UT name |
| `latitude` | float | `9.9319` | Geographic latitude |
| `longitude` | float | `76.27` | Geographic longitude |
| `categories` | JSON array | `["beach"]` | Primary categories |
| `sub_categories` | JSON array | `[]` | Subcategories (often empty) |
| `tags` | JSON array | `["tourism", "travel"]` | Tags for filtering |
| `cost_per_day` | integer | `1000` | Estimated daily cost in INR |
| `rating` | float | `4.5` | Rating out of 5 |
| `description` | string | `Fort Kochi Beach is...` | Long description |
| `visit_duration_hours` | integer | `1` | Recommended visit duration |
| `best_time_to_visit` | string | `Oct-Mar` | Best season |
| `photos` | JSON array | `[]` | Photo URLs (mostly empty) |
| `website_url` | string | `` | Official website (mostly empty) |
| `google_maps_url` | string | `` | Google Maps link (mostly empty) |
| `opening_hours` | string | `9 AM - 6 PM` | Operating hours |
| `entry_fee` | integer | `0` | Entry fee in INR |
| `is_active` | boolean | `true` | Whether destination is active |
| `nearby_attractions` | JSON array | `[]` | Nearby places (mostly empty) |
| `facilities` | JSON array | `[]` | Available facilities (mostly empty) |
| `created_at` | timestamp | `2026-01-23T...` | Creation timestamp |
| `updated_at` | timestamp | `2026-01-23T...` | Last update timestamp |

---

## ✅ Verification Steps

### After Insertion

1. **Count Total Records**
   ```sql
   SELECT COUNT(*) as total_destinations FROM destinations;
   ```

2. **Check New Records by State**
   ```sql
   SELECT state, COUNT(*) as count FROM destinations 
   WHERE state IN ('Kerala', 'Tamil Nadu', 'Karnataka')
   GROUP BY state;
   ```

3. **Sample a Few Records**
   ```sql
   SELECT id, name, city, state, rating FROM destinations 
   WHERE state = 'Kerala' LIMIT 5;
   ```

4. **Check for Duplicates**
   ```sql
   SELECT id, COUNT(*) FROM destinations 
   GROUP BY id HAVING COUNT(*) > 1;
   ```

---

## 🐛 Troubleshooting

### Issue: "SUPABASE_KEY environment variable not set"

**Solution:**
```powershell
# PowerShell
$env:SUPABASE_KEY = "your-api-key"
python INSERT_DESTINATIONS_BULK.py

# Or add to system environment permanently (Windows Settings)
```

### Issue: "Connection refused" or Timeout

**Solutions:**
- Check internet connection
- Verify `SUPABASE_URL` is correct
- Check API key validity in Supabase Dashboard
- Try reducing `batch_size` in the script (e.g., 25 instead of 50)

### Issue: "Duplicate key value violates unique constraint"

**Solution:**
- The script automatically checks for duplicates
- If you get this error, the script is working correctly (skipping existing records)
- Previous batch may have already inserted these records

### Issue: Some Records Failed to Insert

**Solution:**
1. Check the error message in the output
2. Verify CSV file isn't corrupted
3. Ensure all required fields are populated
4. Re-run the script (it will skip existing records)

---

## 📈 Performance Notes

| Metric | Expected Value |
|--------|-----------------|
| **Insertion Time** | 2-5 minutes for 476 records |
| **Network Bandwidth** | ~2-5 MB |
| **API Rate Limit** | Usually no issues at this scale |

---

## 🔐 Security Notes

1. **API Key Safety**
   - Never commit `SUPABASE_KEY` to version control
   - Use `.env` files with proper gitignore
   - Rotate keys periodically

2. **Data Validation**
   - CSV data is automatically type-checked
   - Invalid entries are logged but non-blocking
   - Empty cells are handled gracefully

---

## 📞 Support & Next Steps

After successful insertion:

1. **Update Frontend** to use new destinations
2. **Verify in App** that new places appear in search/explore
3. **Test Search** for Kerala, Tamil Nadu, Karnataka destinations
4. **Check Maps** integration shows correct coordinates
5. **Monitor Analytics** for user engagement with new content

---

## 📚 Additional Resources

- [Supabase Python Client Documentation](https://supabase.com/docs/reference/python)
- [GoTrip Database Schema](SUPABASE_SETUP.md)
- [Data Integration Guide](DATA_INTEGRATION_COMPLETE.md)

---

**Last Updated:** 2026-01-23  
**CSV Version:** new_dataset.csv  
**Total Records:** 476  
**Status:** Ready for insertion ✅
