import os
import json
import base64
import requests
import hashlib
from bs4 import BeautifulSoup
import firebase_admin
from firebase_admin import credentials, firestore, messaging
import google.generativeai as genai

# --- 1. AUTHENTICATION ---
if os.environ.get('FIREBASE_JSON_BASE64'):
    # Production: Decode the key from GitHub Secrets
    decoded_key = base64.b64decode(os.environ.get('FIREBASE_JSON_BASE64'))
    cred_dict = json.loads(decoded_key)
    cred = credentials.Certificate(cred_dict)
else:
    # Local Testing: Use the file on your computer
    cred = credentials.Certificate("backend_automation/service-account.json")

if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

db = firestore.client()
genai.configure(api_key=os.environ.get("GEMINI_API_KEY"))

# --- 2. SCRAPER LOGIC ---
def scrape_citk():
    print("🕵️ Scanning CITK Website...")
    url = "https://www.cit.ac.in/" 
    
    try:
        response = requests.get(url, timeout=20)
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # ⚠️ NOTE: This selector finds the "marquee" or notice list. 
        # Since I can't browse the site, this searches for standard links.
        # You may need to adjust 'a' to a specific class like '.notice-item'
        notices = []
        for item in soup.select('marquee a')[:3]: # Get top 3 items
            text = item.get_text(strip=True)
            link = item.get('href')
            if link and not link.startswith('http'):
                link = "https://www.cit.ac.in" + link
            
            if text:
                notices.append({'text': text, 'link': link})
            
        if notices:
            print(f"✅ Found {len(notices)} notices. Processing the newest one...")
            process_notice(notices[0])
        else:
            print("⚠️ No notices found matching the selector.")
            
    except Exception as e:
        print(f"❌ Scrape Error: {e}")

# --- 3. AI PROCESSING ---
def process_notice(notice):
    text = notice['text']
    link = notice['link']
    
    # Generate ID to prevent duplicate processing
    notice_id = hashlib.md5(text.encode()).hexdigest()
    doc_ref = db.collection('live_notices').document(notice_id)
    
    if doc_ref.get().exists:
        print("Zap! Notice already processed. Skipping.")
        return

    print("🧠 New Content! Asking Gemini...")
    model = genai.GenerativeModel('gemini-1.5-flash')
    
    prompt = f"""
    Analyze this college notice: "{text}"
    
    Return a valid JSON object (NO markdown) with:
    - "summary": (String) A crisp, exciting 1-sentence summary.
    - "target": (String) 'cse', 'civil', 'hostel', or 'all'.
    """
    
    try:
        response = model.generate_content(prompt)
        clean_json = response.text.replace('```json', '').replace('```', '').strip()
        ai_data = json.loads(clean_json)
        
        # Save to Firestore
        notice_data = {
            "title": "CITK Update",
            "body": ai_data['summary'],
            "original_text": text,
            "link": link,
            "target": ai_data['target'],
            "timestamp": firestore.SERVER_TIMESTAMP,
            "type": "scraped"
        }
        doc_ref.set(notice_data)
        print("💾 Saved to Firestore.")
        
        # Send Notification
        send_alert(notice_data)
        
    except Exception as e:
        print(f"⚠️ AI Processing Failed: {e}")

# --- 4. NOTIFICATION ---
def send_alert(data):
    try:
        print(f"🚀 Sending Notification: {data['body']}")
        message = messaging.Message(
            notification=messaging.Notification(
                title="📢 CITK Live",
                body=data['body'],
            ),
            topic="all", # Default to 'all' for Hackathon demo
        )
        messaging.send(message)
    except Exception as e:
        print(f"⚠️ Notification Failed (Check FCM setup): {e}")

if __name__ == "__main__":
    scrape_citk()