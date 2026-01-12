import firebase_admin
from firebase_admin import credentials, firestore
import json
import os

# --- CONFIGURATION ---
# This is the file you just copied over
JSON_FILE = "backend_automation/citk_master_database.json"
# This is your key (it should already be there)
KEY_FILE = "backend_automation/service-account.json"

def upload_now():
    print("🔥 Connecting to Firebase...")
    
    # 1. Login
    if not firebase_admin._apps:
        cred = credentials.Certificate(KEY_FILE)
        firebase_admin.initialize_app(cred)
    
    db = firestore.client()
    
    # 2. Load Data
    if not os.path.exists(JSON_FILE):
        print(f"❌ Error: Could not find {JSON_FILE}")
        return

    with open(JSON_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)
        print(f"📂 Loaded {len(data)} notices.")

    # 3. Upload in Batches
    batch = db.batch()
    count = 0
    total = 0

    print("🚀 Uploading...")
    for item in data:
        # Create a reference with the unique ID
        doc_ref = db.collection("live_notices").document(item['id'])
        
        # Add to batch
        batch.set(doc_ref, item, merge=True)
        count += 1
        total += 1

        # Commit every 400 items
        if count >= 400:
            batch.commit()
            print(f"   💾 Saved {total} notices...")
            batch = db.batch()
            count = 0

    # Final commit
    if count > 0:
        batch.commit()
    
    print(f"🎉 SUCCESS! {total} notices are now live in your App.")

if __name__ == "__main__":
    upload_now()