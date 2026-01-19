# GoTrip Dataset Generation Guide - COMPREHENSIVE ALL-INDIA

## 🎯 RECOMMENDED LLM & MODEL

**BEST CHOICE: Google Gemini Pro 1.5 with Deep Research** (You have access! ✅)

**Why Gemini Pro 1.5:**
- ✅ Can handle 1M+ token context (generate 500+ destinations in one go)
- ✅ Deep research capability for comprehensive data
- ✅ Strong knowledge of Indian tourism across ALL states
- ✅ Can access internal knowledge + search capabilities
- ✅ Excellent at structured JSON generation

**Settings for Gemini Pro:**
- Temperature: `0.2` (very low for factual accuracy)
- Top-P: `0.9`
- Top-K: `40`
- Max Output Tokens: `50000` (maximum allowed)

---

## 📋 MASTER PROMPT FOR ALL-INDIA COMPREHENSIVE DATASET

Copy this **COMPLETE PROMPT** into Gemini Pro 1.5:

---

### MASTER PROMPT START ⬇️

```
You are an expert Indian tourism database architect with comprehensive knowledge of destinations across all Indian states and union territories.

# MISSION
Generate a COMPLETE, comprehensive JSON dataset of authentic tourism destinations covering ALL major cities, towns, and tourist areas across India. This is for GoTrip, a trip planning application that needs real, locally popular destinations - not just famous tourist spots.

# SCOPE & COVERAGE

## Geographic Coverage - ALL 28 States + 8 UTs:

### North India:
- **Jammu & Kashmir**: Srinagar, Gulmarg, Pahalgam, Sonamarg, Leh, Kargil
- **Ladakh**: Leh, Nubra Valley, Pangong Lake, Tso Moriri, Kargil
- **Himachal Pradesh**: Shimla, Manali, Dharamshala, Kullu, Kasauli, Dalhousie, Spiti Valley
- **Uttarakhand**: Dehradun, Mussoorie, Rishikesh, Haridwar, Nainital, Ranikhet, Auli
- **Punjab**: Amritsar, Chandigarh, Ludhiana, Patiala
- **Haryana**: Gurgaon, Faridabad, Kurukshetra
- **Delhi**: New Delhi (all zones - North, South, East, West, Central)
- **Uttar Pradesh**: Agra, Varanasi, Lucknow, Mathura, Vrindavan, Ayodhya, Allahabad

### West India:
- **Rajasthan**: Jaipur, Udaipur, Jodhpur, Jaisalmer, Pushkar, Bikaner, Mount Abu, Ajmer
- **Gujarat**: Ahmedabad, Surat, Vadodara, Dwarka, Somnath, Rann of Kutch, Gir
- **Maharashtra**: Mumbai, Pune, Aurangabad, Nashik, Mahabaleshwar, Lonavala, Alibaug
- **Goa**: North Goa (Baga, Anjuna, Calangute), South Goa (Palolem, Agonda, Colva)

### South India:
- **Karnataka**: Bangalore, Mysore, Coorg, Hampi, Mangalore, Udupi, Chikmagalur
- **Tamil Nadu**: Chennai, Madurai, Ooty, Kodaikanal, Rameswaram, Kanyakumari, Pondicherry
- **Kerala**: Kochi, Munnar, Alappuzha, Thiruvananthapuram, Wayanad, Thekkady, Kovalam, Varkala
- **Andhra Pradesh**: Visakhapatnam, Vijayawada, Tirupati, Araku Valley
- **Telangana**: Hyderabad, Warangal

### East India:
- **West Bengal**: Kolkata, Darjeeling, Kalimpong, Siliguri, Sundarbans, Digha
- **Odisha**: Bhubaneswar, Puri, Konark, Chilika Lake
- **Bihar**: Patna, Bodh Gaya, Nalanda, Rajgir
- **Jharkhand**: Ranchi, Jamshedpur, Netarhat

### Northeast India:
- **Assam**: Guwahati, Kaziranga, Majuli
- **Sikkim**: Gangtok, Pelling, Lachung, Nathula
- **Meghalaya**: Shillong, Cherrapunji, Mawlynnong
- **Arunachal Pradesh**: Tawang, Ziro, Itanagar
- **Nagaland**: Kohima, Dimapur
- **Manipur**: Imphal, Loktak Lake
- **Tripura**: Agartala, Ujjayanta Palace
- **Mizoram**: Aizawl

### Islands:
- **Andaman & Nicobar**: Port Blair, Havelock, Neil Island
- **Lakshadweep**: Agatti, Bangaram, Kavaratti

## Destination Types Per City:

### For Major Metro Cities (15-25 destinations each):
Mumbai, Delhi, Bangalore, Chennai, Kolkata, Hyderabad, Pune, Ahmedabad

### For Tourist Hub Cities (10-20 destinations each):
Goa, Jaipur, Udaipur, Agra, Varanasi, Kochi, Munnar, Manali, Shimla, Rishikesh, Darjeeling, Mysore

### For Tier 2 Cities (8-15 destinations each):
All state capitals and popular tourist towns

### For Smaller Towns (5-10 destinations each):
Hill stations, beach towns, pilgrimage sites, local attractions

# TARGET: Generate 800-1000+ destinations total covering entire India

# STRICT REQUIREMENTS

## 1. JSON FORMAT
Return ONLY valid JSON array. No markdown, no explanations, no code blocks. Just raw JSON that can be directly parsed.

## 2. MANDATORY FIELDS & CONSTRAINTS

### id (TEXT)
- Format: `{city}_{sequence_number}`
- Example: `mumbai_1`, `kochi_15`, `bangalore_8`
- Use lowercase, no spaces
- Sequential numbering (1, 2, 3...)

### name (TEXT)
- Real, verifiable destination name
- NO generic names like "Local Market" or "Beach Resort"
- Use actual names: "Marine Drive", "Lulu Mall Edapally", "Victoria Memorial"

### city (TEXT)
- Exact city name
- Example: "Mumbai", "Kochi", "Bangalore", "Kolkata"

### state (TEXT)
- Full state name
- Example: "Maharashtra", "Kerala", "Karnataka", "West Bengal"

### latitude (DECIMAL)
- Real GPS coordinates (verify accuracy!)
- Format: Decimal degrees with 6-8 decimal places
- Example: 19.076090, 12.971599

### longitude (DECIMAL)
- Real GPS coordinates (verify accuracy!)
- Format: Decimal degrees with 6-8 decimal places
- Example: 72.877426, 77.594566

### categories (TEXT ARRAY)
**CRITICAL: Use ONLY these 8 values. NO other categories allowed:**
- `"beach"` - Beaches, coastal areas, seaside
- `"history"` - Historical monuments, forts, archaeological sites, museums
- `"adventure"` - Trekking, water sports, theme parks, adventure activities
- `"food"` - Restaurants, food streets, markets with cuisine focus, cafes
- `"shopping"` - Malls, markets, shopping streets, bazaars
- `"nature"` - Parks, gardens, waterfalls, forests, wildlife
- `"religious"` - Temples, churches, mosques, religious sites
- `"cultural"` - Art galleries, cultural centers, theaters, festivals

**Rules:**
- Each destination should have 1-3 categories
- Most common combinations: ["beach", "food"], ["history", "cultural"], ["shopping", "food"], ["nature", "adventure"]
- DO NOT invent new categories

### cost_per_day (INTEGER)
- Average total cost in Indian Rupees (₹)
- Includes: Entry fee + food + local transport + activities
- Realistic ranges:
  - Budget (parks, temples): ₹800 - ₹1500
  - Mid-range (museums, markets): ₹1500 - ₹2500
  - Premium (malls, resorts, adventure parks): ₹2500 - ₹4000
  - Luxury (fine dining, exclusive experiences): ₹4000+

### rating (DECIMAL)
- Range: 3.5 to 5.0 (one decimal place)
- Realistic distribution:
  - 4.3 to 4.6: Most destinations (60%)
  - 4.0 to 4.2: Good destinations (25%)
  - 4.7 to 4.9: Exceptional destinations (10%)
  - 3.8 to 3.9: Average destinations (4%)
  - 5.0: Rare, iconic landmarks only (1%)

### description (TEXT)
- 1-2 sentences, concise and informative
- Highlight: Key features, activities, what makes it special
- Example: "India's largest mall with 400+ stores, multiplex cinema, food court, and entertainment zones. Popular shopping destination for locals and tourists."
- Avoid: Marketing fluff, "must-visit", "amazing", "stunning"

### visit_duration_hours (INTEGER)
**CRITICAL for multi-destination day planning:**
- Range: 1 to 8 hours
- Guidelines:
  - **1-2 hours**: Quick stops (restaurants, viewpoints, small markets)
  - **3-4 hours**: Half-day (museums, beaches, temples, shopping streets)
  - **5-6 hours**: Most of day (large malls, theme parks, gardens)
  - **7-8 hours**: Full day (resorts, hill stations, safari parks, multi-activity sites)

### best_time_to_visit (TEXT)
- Allowed values:
  - `"year_round"`: Indoor attractions, cities
  - `"summer"`: Hill stations, water parks (April-June)
  - `"winter"`: Beaches, outdoor sites (Nov-Feb)
  - `"monsoon"`: Waterfalls, greenery (July-Sep)
  - `"oct_to_mar"`: Pleasant weather destinations
  - `"apr_to_jun"`: Specific seasonal attractions
- Choose based on real weather patterns

### sub_categories (TEXT ARRAY) - OPTIONAL
- More specific classification
- Examples: ["mall", "temple", "museum", "waterfall", "fort", "palace", "market", "cafe", "viewpoint", "zoo", "aquarium"]
- 0-3 values

### tags (TEXT ARRAY) - OPTIONAL
- Practical tags for filtering
- Allowed: ["family_friendly", "budget_friendly", "luxury", "offbeat", "popular", "instagram_worthy", "wheelchair_accessible", "pet_friendly", "night_life"]
- 1-4 values per destination

### opening_hours (TEXT) - OPTIONAL
- Format: "9:00 AM - 6:00 PM" or "24 hours" or "Varies"
- Use 12-hour format with AM/PM

### entry_fee (INTEGER) - OPTIONAL
- In Indian Rupees (₹)
- Use 0 for free entry
- Example: 50, 200, 500, 0

### nearby_attractions (TEXT ARRAY) - OPTIONAL
- IDs of other destinations in same dataset
- Example: ["mumbai_2", "mumbai_5"]
- Only include if within 10km

### facilities (TEXT ARRAY) - OPTIONAL
- Allowed: ["parking", "restroom", "wheelchair_access", "food_available", "guided_tours", "wifi", "atm", "lockers"]
- 0-5 values

## 3. ACCURACY REQUIREMENTS

### Verify Every Detail:
✅ Real destination names (Google Maps verified)
✅ Correct GPS coordinates (±0.001 precision)
✅ Realistic costs based on 2025-2026 prices
✅ Accurate descriptions (no hallucinations)

### Geographic Distribution:
- Cover all areas of the city
- Include mix of: Central attractions, suburbs, nearby areas (up to 50km)
- For beach cities: Include multiple beaches
- For historical cities: Include multiple monuments/museums
- For metro cities: Include various shopping/dining areas

### Category Distribution (aim for):
- 25% nature/beach
- 25% history/cultural/religious
- 20% shopping/food
- 15% adventure
- 15% mixed categories

## 4. OUTPUT FORMAT

```json
[
  {
    "id": "mumbai_1",
    "name": "Gateway of India",
    "city": "Mumbai",
    "state": "Maharashtra",
    "latitude": 18.921984,
    "longitude": 72.834656,
    "categories": ["history", "cultural"],
    "sub_categories": ["monument", "landmark"],
    "tags": ["popular", "instagram_worthy", "family_friendly"],
    "cost_per_day": 1200,
    "rating": 4.6,
    "description": "Iconic arch monument built during British Raj, overlooks Arabian Sea. Popular tourist spot with boat rides to Elephanta Caves.",
    "visit_duration_hours": 2,
    "best_time_to_visit": "winter",
    "opening_hours": "24 hours",
    "entry_fee": 0,
    "nearby_attractions": ["mumbai_2", "mumbai_3"],
    "facilities": ["parking", "restroom", "food_available"]
  },
  {
    "id": "mumbai_2",
    "name": "Colaba Causeway Market",
    "city": "Mumbai",
    "state": "Maharashtra",
    "latitude": 18.914630,
    "longitude": 72.826691,
    "categories": ["shopping", "food"],
    "sub_categories": ["market", "street_shopping"],
    "tags": ["budget_friendly", "popular"],
    "cost_per_day": 1800,
    "rating": 4.3,
    "description": "Bustling street market offering clothes, accessories, jewelry, antiques and street food. Famous for bargain shopping and local snacks.",
    "visit_duration_hours": 3,
    "best_time_to_visit": "year_round",
    "opening_hours": "10:00 AM - 10:00 PM",
    "entry_fee": 0,
    "nearby_attractions": ["mumbai_1"],
    "facilities": ["restroom", "food_available", "atm"]
  }
]
```

# TARGET: Generate 800-1000+ destinations total covering entire India

# JSON FORMAT & FIELD REQUIREMENTS

## MANDATORY FIELDS (exact same as before):

```json
{
  "id": "city_sequencenumber",
  "name": "Real Destination Name",
  "city": "City Name",
  "state": "State Name",
  "latitude": 12.345678,
  "longitude": 76.543210,
  "categories": ["beach", "food"],
  "sub_categories": ["beach_resort", "seafood"],
  "tags": ["family_friendly", "popular"],
  "cost_per_day": 2000,
  "rating": 4.5,
  "description": "Brief factual description in 1-2 sentences",
  "visit_duration_hours": 3,
  "best_time_to_visit": "winter",
  "opening_hours": "9:00 AM - 6:00 PM",
  "entry_fee": 100,
  "nearby_attractions": ["city_2", "city_5"],
  "facilities": ["parking", "restroom", "food_available"]
}
```

## STRICT CONSTRAINTS:

### Categories (ONLY these 8):
- `beach` - Beaches, coastal areas
- `history` - Monuments, forts, museums, archaeological sites
- `adventure` - Trekking, water sports, adventure parks, zip-lining
- `food` - Restaurants, food streets, markets, cafes, local cuisine
- `shopping` - Malls, markets, shopping streets, bazaars
- `nature` - Parks, waterfalls, forests, wildlife, gardens
- `religious` - Temples, churches, mosques, pilgrimage sites
- `cultural` - Museums, galleries, theaters, cultural centers

### ID Format:
- Use city name abbreviation or short form
- Format: `{city_short}_{number}`
- Examples: `mumbai_1`, `del_15`, `blr_8`, `kochi_12`, `goa_north_5`
- No spaces, lowercase only

### Coordinates:
- Must be REAL GPS coordinates (8 decimal places)
- Verify accuracy - use your knowledge database
- Format: Decimal degrees (e.g., 19.076090, 72.877426)

### Cost Per Day (Indian Rupees):
- Budget: ₹800-1500 (parks, temples, local markets)
- Mid-range: ₹1500-2500 (museums, beaches, shopping)
- Premium: ₹2500-4000 (malls, adventure parks, resorts)
- Luxury: ₹4000+ (fine dining, exclusive experiences)

### Visit Duration Hours:
- 1-2: Quick stops (viewpoints, temples, cafes)
- 3-4: Half-day (museums, beaches, markets)
- 5-6: Most of day (theme parks, large malls)
- 7-8: Full day (resorts, safari, hill stations)

### Ratings (realistic distribution):
- 4.3-4.6: 60% of destinations
- 4.0-4.2: 25%
- 4.7-4.9: 10%
- 3.8-3.9: 4%
- 5.0: 1% (only iconic landmarks)

### Best Time to Visit:
- `year_round`, `summer`, `winter`, `monsoon`, `oct_to_mar`, `apr_to_jun`

# CRITICAL INSTRUCTIONS:

## 1. Include LOCAL Favorites:
Don't just list famous tourist spots. Include:
- ✅ Popular local restaurants (not chains - authentic local cuisine)
- ✅ Neighborhood markets (Crawford Market Mumbai, T Nagar Chennai, Chickpet Bangalore)
- ✅ Local beaches (not just famous ones)
- ✅ City parks and gardens where locals actually go
- ✅ Street food areas (Juhu Beach chaat, Connaught Place Delhi)
- ✅ Lesser-known temples and cultural sites
- ✅ Viewpoints and sunset spots
- ✅ Local shopping streets (not just malls)

## 2. Geographic Distribution:
For each city, cover:
- City center attractions
- Suburban areas
- Nearby towns (within 50-100km)
- Beach towns for coastal cities
- Hill stations for plains cities
- Weekend getaway spots

## 3. Category Balance (approximate per city):
- 20-25%: Beach/Nature
- 20-25%: History/Cultural/Religious
- 20-25%: Shopping/Food
- 15-20%: Adventure
- 10-15%: Mixed categories

## 4. Real Names Only:
❌ NO: "Local Beach", "City Mall", "Famous Temple", "Popular Restaurant"
✅ YES: "Juhu Beach", "Lulu Mall Edapally", "Golden Temple Amritsar", "Karim's Delhi"

## 5. Nearby Attractions:
- Include beaches near landlocked cities (e.g., Digha/Mandarmani for Kolkata, Gokarna for Bangalore)
- Distance up to 200km is acceptable for 3-4 day trips

# OUTPUT FORMAT:

Return a SINGLE JSON array with ALL destinations for ALL cities:

```json
[
  {
    "id": "mumbai_1",
    "name": "Gateway of India",
    "city": "Mumbai",
    "state": "Maharashtra",
    "latitude": 18.921984,
    "longitude": 72.834656,
    "categories": ["history", "cultural"],
    "sub_categories": ["monument"],
    "tags": ["popular", "instagram_worthy"],
    "cost_per_day": 1200,
    "rating": 4.6,
    "description": "Iconic arch monument built during British Raj overlooking Arabian Sea. Popular tourist spot with boat rides to Elephanta Caves.",
    "visit_duration_hours": 2,
    "best_time_to_visit": "winter",
    "opening_hours": "24 hours",
    "entry_fee": 0,
    "nearby_attractions": ["mumbai_2", "mumbai_3"],
    "facilities": ["parking", "restroom", "food_available"]
  },
  ... (continue for all 800-1000 destinations)
]
```

# GENERATION STRATEGY:

## Phase 1: Metro Cities (200 destinations)
Start with 8 major metros, 25 destinations each:
- Mumbai (Maharashtra) - 25
- Delhi (Delhi) - 25
- Bangalore (Karnataka) - 25
- Chennai (Tamil Nadu) - 25
- Kolkata (West Bengal) - 25
- Hyderabad (Telangana) - 25
- Pune (Maharashtra) - 25
- Ahmedabad (Gujarat) - 25

## Phase 2: Tourist Hubs (300 destinations)
Major tourist destinations, 15-20 each:
- Goa (North + South) - 20
- Jaipur (Rajasthan) - 20
- Udaipur (Rajasthan) - 15
- Agra (UP) - 15
- Varanasi (UP) - 15
- Kochi (Kerala) - 20
- Munnar (Kerala) - 15
- Alappuzha (Kerala) - 15
- Thiruvananthapuram (Kerala) - 15
- Manali (HP) - 15
- Shimla (HP) - 15
- Rishikesh (Uttarakhand) - 15
- Darjeeling (WB) - 15
- Mysore (Karnataka) - 15
- Pondicherry (Puducherry) - 15
- Coorg (Karnataka) - 10
- Hampi (Karnataka) - 10

## Phase 3: Tier 2 Cities (200 destinations)
State capitals and regional hubs, 8-12 each:
- Amritsar, Chandigarh, Lucknow, Bhopal, Indore, Patna
- Bhubaneswar, Ranchi, Guwahati, Gangtok, Shillong
- Visakhapatnam, Vijayawada, Tirupati, Madurai, Coimbatore
- Surat, Vadodara, Nashik, Aurangabad, Nagpur
- Jodhpur, Jaisalmer, Bikaner, Ajmer, Pushkar

## Phase 4: Popular Destinations (150 destinations)
Hill stations, beaches, pilgrimage, 5-10 each:
- Ooty, Kodaikanal, Yercaud, Mahabaleshwar, Lonavala
- Puri, Konark, Gopalpur, Digha, Mandarmani
- Gokarna, Udupi, Mangalore, Varkala, Kovalam
- Nainital, Mussoorie, Dharamshala, Dalhousie, Kasauli
- Wayanad, Thekkady, Rameshwaram, Kanyakumari
- Leh-Ladakh, Srinagar, Gulmarg, Pahalgam
- Andaman (Port Blair, Havelock)

## Phase 5: Emerging & Offbeat (100 destinations)
Lesser-known but locally popular, 3-8 each:
- Ziro Valley, Tawang, Majuli, Cherrapunji
- Spiti Valley, Chitkul, Tirthan Valley
- Chikmagalur, Sakleshpur, Kabini
- Araku Valley, Lambasingi
- Tso Moriri, Pangong, Nubra Valley
- Gokarna, Om Beach, Kumta
- Mandu, Orchha, Khajuraho
- Sundarbans, Kalimpong, Sandakphu

# DATA SOURCES TO LEVERAGE:

Use your comprehensive knowledge from:
- ✅ Google Maps popular destinations
- ✅ TripAdvisor top attractions
- ✅ MakeMyTrip/Yatra popular bookings
- ✅ Instagram location tags (popular spots)
- ✅ Local tourism board recommendations
- ✅ Travel blogs and guides
- ✅ Your training data on Indian geography and tourism

# QUALITY REQUIREMENTS:

Before finalizing, verify:
- [ ] All destinations are REAL (exist on Google Maps)
- [ ] Coordinates are accurate (±0.001 precision)
- [ ] Categories use ONLY the 8 allowed values
- [ ] IDs are unique (no duplicates across 1000 destinations)
- [ ] Costs are realistic for 2025-2026
- [ ] Mix of famous + local popular destinations
- [ ] Geographic coverage of all major states
- [ ] Balanced category distribution
- [ ] Visit durations are logical
- [ ] Nearby attractions are within reasonable distance

# FINAL OUTPUT INSTRUCTIONS:

1. Generate comprehensive JSON array with 800-1000 destinations
2. Organize by region (North → West → South → East → Northeast)
3. Within each region, group by state
4. Within each state, group by city
5. Return ONLY valid JSON - no explanations, no markdown
6. If output is too large for one response, split into multiple parts (Part 1/3, Part 2/3, etc.) clearly labeled

# START GENERATION NOW:

Generate the complete All-India tourism destination dataset following all specifications above.

Return format: Pure JSON array starting with `[` and ending with `]`
```

### MASTER PROMPT END ⬆️

---

## 🚀 HOW TO USE THIS COMPREHENSIVE APPROACH

### Option 1: Single Generation (Recommended for Gemini 1.5 Pro)

1. **Open Gemini AI Studio**: https://aistudio.google.com/
2. **Select Model**: Gemini 1.5 Pro (NOT 1.0)
3. **Set Parameters**:
   - Temperature: `0.2`
   - Max Output: `50000` tokens (maximum)
4. **Paste entire prompt** above
5. **Run** - May take 2-5 minutes for complete generation
6. **Save output** as `destinations_all_india.json`

### Option 2: Batched Generation (if output limits hit)

If Gemini splits output into parts:
1. Copy Part 1, save as `destinations_part1.json`
2. Copy Part 2, save as `destinations_part2.json`  
3. Repeat for all parts
4. I'll provide a merge script

### Option 3: Python Script with Gemini API (Automated)

I can create a Python script that:
- Uses Gemini API with your key
- Generates destinations in batches automatically
- Combines all outputs
- Validates JSON
- Saves to single file

---

## 📝 NEXT STEPS AFTER GENERATION

### 1. Validation Script

I'll create Python script to:
- ✅ Validate JSON syntax
- ✅ Check for duplicate IDs
- ✅ Verify category values
- ✅ Check coordinate ranges (lat: 6-37°N, lng: 68-97°E for India)
- ✅ Ensure all required fields present
- ✅ Generate statistics report

### 2. SQL Conversion Script

Convert JSON → PostgreSQL INSERT statements:
```python
python convert_json_to_sql.py destinations_all_india.json
# Output: INSERT_DESTINATIONS.sql
```

### 3. Import to Supabase

```sql
-- Run in Supabase SQL Editor
-- Will insert 800-1000 destinations in batches
```

---

## ⚡ ALTERNATIVE: Fully Automated Python Script

Want me to create a complete automation script that:
1. **Calls Gemini API** with your key
2. **Generates all destinations** automatically in batches
3. **Validates** output
4. **Converts to SQL**
5. **Uploads to Supabase** directly

Let me know and I'll create it! This way you just run:
```bash
python generate_complete_dataset.py
```

And it handles everything! 🚀

---

## 💡 EXPECTED OUTPUT SIZE

- **800-1000 destinations** across India
- **~50-60KB JSON** file size
- **All 28 states + 8 UTs** covered
- **Mix of famous + locally popular** spots
- **Ready for Supabase** import

Would you like me to create the automated Python script approach instead? It would be much more reliable than manual prompting!

