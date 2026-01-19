import csv

with open('destinations_cleaned.csv', encoding='utf-8') as f:
    data = list(csv.DictReader(f))

print("📊 TRANSFORMATION SUMMARY\n")
print(f"✅ Total destinations: {len(data)}")

# Category counts
cats = {}
for row in data:
    for c in row['categories'].strip('{}').split(','):
        if c:
            cats[c] = cats.get(c, 0) + 1

print("\n📁 Categories:")
for k, v in sorted(cats.items()):
    print(f"  {k}: {v}")

# State counts
states = {}
for row in data:
    state = row['state']
    states[state] = states.get(state, 0) + 1

print("\n🗺️ Top 10 States:")
for k, v in sorted(states.items(), key=lambda x: x[1], reverse=True)[:10]:
    print(f"  {k}: {v}")

print(f"\n💰 Cost Range: ₹{min(int(row['cost_per_day']) for row in data)}-{max(int(row['cost_per_day']) for row in data)}")
print(f"⭐ Rating Range: {min(float(row['rating']) for row in data):.1f}-{max(float(row['rating']) for row in data):.1f}")
print("\n✨ Ready for Supabase import!")
