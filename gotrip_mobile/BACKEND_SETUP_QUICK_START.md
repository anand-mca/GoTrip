# Backend Setup Guide for GoTrip API

## Quick Start - Choose Your Backend

### Option 1: Node.js + Express (Recommended for beginners)

#### Step 1: Create backend folder

```bash
mkdir gotrip-backend
cd gotrip-backend
npm init -y
```

#### Step 2: Install dependencies

```bash
npm install express cors dotenv axios supabase nodemon
npm install --save-dev @types/node
```

#### Step 3: Create `.env` file

```
PORT=8000
DATABASE_URL=postgresql://user:password@localhost:5432/gotrip
GOOGLE_PLACES_API_KEY=your_key_here
AMADEUS_API_KEY=your_key_here
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_key
```

#### Step 4: Create `server.js`

```javascript
const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.get('/api/health', (req, res) => {
  res.json({ status: 'Backend is running!' });
});

// Import and use routes
app.use('/api/destinations', require('./routes/destinations'));
app.use('/api/hotels', require('./routes/hotels'));
app.use('/api/activities', require('./routes/activities'));
app.use('/api/categories', require('./routes/categories'));

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: err.message });
});

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => {
  console.log(`✅ Backend running on http://localhost:${PORT}`);
});
```

#### Step 5: Create routes/destinations.js

```javascript
const express = require('express');
const axios = require('axios');
const router = express.Router();

// Recommendation endpoint
router.post('/recommendations', async (req, res) => {
  try {
    const { preferences, max_budget, days, location } = req.body;

    // Validate input
    if (!preferences || !max_budget || !days || !location) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Mock data - Replace with real API calls
    const mockDestinations = [
      {
        id: 'beach1',
        name: 'Goa Beach Paradise',
        category: 'beach',
        latitude: 15.4909,
        longitude: 73.8278,
        cost: 8000,
        days: 3,
        distance: 1800,
        rating: 4.5,
        reviews: 2345,
        description: 'Beautiful beaches with water sports',
        image: 'https://via.placeholder.com/300x200?text=Goa+Beach',
      },
      {
        id: 'adventure1',
        name: 'Himalayas Adventure',
        category: 'adventure',
        latitude: 32.2190,
        longitude: 77.1605,
        cost: 12000,
        days: 4,
        distance: 450,
        rating: 4.7,
        reviews: 1890,
        description: 'Trekking and mountaineering',
        image: 'https://via.placeholder.com/300x200?text=Himalayas',
      },
      {
        id: 'food1',
        name: 'Delhi Food Tour',
        category: 'food',
        latitude: 28.6139,
        longitude: 77.2090,
        cost: 2000,
        days: 1,
        distance: 0,
        rating: 4.6,
        reviews: 3456,
        description: 'Street food and culinary experience',
        image: 'https://via.placeholder.com/300x200?text=Delhi+Food',
      },
      {
        id: 'history1',
        name: 'Agra Historical Tour',
        category: 'history',
        latitude: 27.1751,
        longitude: 78.0421,
        cost: 5000,
        days: 2,
        distance: 240,
        rating: 4.8,
        reviews: 5000,
        description: 'Taj Mahal and Agra Fort',
        image: 'https://via.placeholder.com/300x200?text=Taj+Mahal',
      },
      {
        id: 'nature1',
        name: 'Kerala Backwaters',
        category: 'nature',
        latitude: 9.5615,
        longitude: 76.3544,
        cost: 10000,
        days: 3,
        distance: 2500,
        rating: 4.7,
        reviews: 2100,
        description: 'Serene backwater cruise',
        image: 'https://via.placeholder.com/300x200?text=Kerala',
      },
    ];

    // Filter by preferences and budget
    const filtered = mockDestinations
      .filter(d => preferences.includes(d.category) && d.cost <= max_budget)
      .sort((a, b) => b.rating - a.rating)
      .slice(0, 10);

    res.json({ 
      destinations: filtered,
      total: filtered.length,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Search endpoint
router.get('/search', async (req, res) => {
  try {
    const { q } = req.query;

    if (!q) {
      return res.status(400).json({ error: 'Query parameter required' });
    }

    const mockResults = [
      { id: 'beach1', name: 'Goa Beach', category: 'beach' },
      { id: 'adventure1', name: 'Adventure Sports', category: 'adventure' },
    ].filter(item => 
      item.name.toLowerCase().includes(q.toLowerCase())
    );

    res.json({ results: mockResults });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get single destination
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const destination = {
      id,
      name: 'Sample Destination',
      description: 'Detailed description here',
      rating: 4.5,
    };

    res.json({ destination });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
```

#### Step 6: Create routes/hotels.js

```javascript
const express = require('express');
const router = express.Router();

router.get('/', async (req, res) => {
  try {
    const { destination, check_in, check_out, max_price } = req.query;

    const mockHotels = [
      {
        id: 'hotel1',
        name: 'Luxury Resort',
        price: 5000,
        rating: 4.8,
        rooms: 50,
        amenities: ['Pool', 'Gym', 'Restaurant'],
      },
      {
        id: 'hotel2',
        name: 'Budget Hotel',
        price: 1500,
        rating: 4.2,
        rooms: 30,
        amenities: ['WiFi', 'AC'],
      },
    ];

    const filtered = max_price 
      ? mockHotels.filter(h => h.price <= parseInt(max_price))
      : mockHotels;

    res.json({ hotels: filtered });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
```

#### Step 7: Create routes/activities.js

```javascript
const express = require('express');
const router = express.Router();

router.post('/search', async (req, res) => {
  try {
    const { destination, categories, max_price } = req.body;

    const mockActivities = [
      {
        id: 'act1',
        name: 'City Tour',
        price: 500,
        duration: '4 hours',
        rating: 4.5,
      },
      {
        id: 'act2',
        name: 'Adventure Trekking',
        price: 1200,
        duration: '1 day',
        rating: 4.7,
      },
    ];

    const filtered = max_price
      ? mockActivities.filter(a => a.price <= max_price)
      : mockActivities;

    res.json({ activities: filtered });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
```

#### Step 8: Create routes/categories.js

```javascript
const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  const categories = [
    'beach',
    'adventure',
    'food',
    'history',
    'shopping',
    'nature',
    'religious',
    'cultural',
  ];

  res.json({ categories });
});

module.exports = router;
```

#### Step 9: Update package.json

```json
{
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  }
}
```

#### Step 10: Run the backend

```bash
npm run dev
```

Should output:
```
✅ Backend running on http://localhost:8000
```

---

### Option 2: Python + FastAPI

#### Step 1: Create virtual environment

```bash
python -m venv venv
venv\Scripts\activate  # Windows
source venv/bin/activate  # Mac/Linux
```

#### Step 2: Install dependencies

```bash
pip install fastapi uvicorn python-dotenv
```

#### Step 3: Create `main.py`

```python
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class RecommendationRequest(BaseModel):
    preferences: List[str]
    max_budget: int
    days: int
    location: str

@app.get("/api/health")
async def health():
    return {"status": "Backend is running!"}

@app.post("/api/destinations/recommendations")
async def get_recommendations(request: RecommendationRequest):
    destinations = [
        {
            "id": "beach1",
            "name": "Goa Beach Paradise",
            "category": "beach",
            "cost": 8000,
            "days": 3,
            "distance": 1800,
            "rating": 4.5,
        }
    ]
    
    filtered = [
        d for d in destinations 
        if d["category"] in request.preferences and d["cost"] <= request.max_budget
    ]
    
    return {"destinations": filtered}

@app.get("/api/destinations/search")
async def search_destinations(q: str):
    results = [
        {"id": "beach1", "name": "Goa Beach", "category": "beach"},
    ]
    return {"results": [r for r in results if q.lower() in r["name"].lower()]}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

#### Step 4: Run

```bash
python main.py
```

---

## Integration Checklist

- [ ] Backend server created and running on localhost:8000
- [ ] `/api/health` endpoint returning success
- [ ] `/api/destinations/recommendations` endpoint implemented
- [ ] Flutter app can reach backend (no connection errors)
- [ ] Mock data working in recommendations
- [ ] API responses match expected format
- [ ] Error handling implemented
- [ ] CORS configured properly
- [ ] Environment variables set up
- [ ] Database integration (optional, can use mock data first)

## Testing API Endpoints

### Using Postman or curl:

```bash
# Health check
curl http://localhost:8000/api/health

# Get recommendations
curl -X POST http://localhost:8000/api/destinations/recommendations \
  -H "Content-Type: application/json" \
  -d '{
    "preferences": ["beach", "adventure"],
    "max_budget": 15000,
    "days": 5,
    "location": "Delhi"
  }'
```

---

## Next: Connect to Real Data

Once backend is working, integrate:

1. **Google Places API**: For destination discovery
2. **Amadeus API**: For hotel/flight prices
3. **Supabase**: To store destinations and user data
4. **MakeMyTrip/Airbnb APIs**: For real pricing (if available)

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Port 8000 already in use | Use different port or kill process: `lsof -i :8000` |
| CORS errors | Check CORS middleware configuration |
| Cannot reach backend from Flutter | Ensure backend is running and URL is correct |
| Connection timeout | Check if backend is responsive with `/api/health` |

