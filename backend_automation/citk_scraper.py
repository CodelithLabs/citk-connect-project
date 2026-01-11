import os
import json
import base64
import requests
import hashlib
from datetime import datetime
from bs4 import BeautifulSoup
import firebase_admin
from firebase_admin import credentials, firestore, messaging
import google.generativeai as genai

# --- 1. ROBUST AUTHENTICATION ---
firebase_key_b64 = os.environ.get('FIREBASE_JSON_BASE64')

if firebase_key_b64:
    # Production Mode (GitHub Actions)
    decoded_key = base64.b64decode(firebase_key_b64)
    cred_dict = json.loads(decoded_key)
    cred = credentials.Certificate(cred_dict)
else:
    # Development Mode (Local Laptop)
    print("⚠️ Using local service-account.json")
    cred = credentials.Certificate("backend_automation/service-account.json")

if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

db = firestore.client()

# Fix for Pylance typing issues
genai.configure(api_key=os.environ.get("GEMINI_API_KEY")) # type: ignore

# --- 2. THE SCRAPER ENGINE (Targeting the Full Notice Board) ---
def scrape_citk():
    print("🕵️ Starting CITK Intelligence Scan...")
    
    # Target: The specific ALL NOTICES page
    url = "https://cit.ac.in/pages-notices-all" 
    
    try:
        # User Agent makes us look like a real browser, not a bot
        headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'}
        response = requests.get(url, headers=headers, timeout=30)
        soup = BeautifulSoup(response.text, 'html.parser')
        
        notices_found = []
        
        # STRATEGY: Find the main table rows (tr)
        # The page structure usually has rows with: [Index, Title, File Link, Date]
        rows = soup.find_all('tr')
        
        for row in rows[:10]: # Check top 10 rows (skip header if possible)
            cols = row.find_all('td')
            
            # We need at least 3 columns to be a valid notice row
            if len(cols) >= 3:
                # Usually Column 1 is Title, Column 2 is Attachment
                # But we scan for the text and link dynamically
                
                # Extract text from the second column (Title)
                text = cols[1].get_text(strip=True)
                
                # Extract link from the 'a' tag in the row
                link_tag = row.find('a', href=True)
                raw_link = link_tag['href'] if link_tag else ""
                
                link = str(raw_link)
                if link and not link.startswith('http'):
                    link = "https://cit.ac.in" + link
                
                # Filter out junk rows (headers, empty lines)
                if text and len(text) > 5 and "Title" not in text:
                    notices_found.append({'text': text, 'link': link})
        
        if notices_found:
            print(f"✅ Found {len(notices_found)} notices. Analyzing the newest one...")
            # Process the very top notice (Newest)
            process_data_pipeline(notices_found[0]) 
        else:
            print("⚠️ No valid notice rows found. Website structure might have changed.")
            
    except Exception as e:
        print(f"❌ Critical Scan Error: {e}")

# --- 3. THE GEMINI AI PIPELINE ---
def process_data_pipeline(raw_data):
    text = raw_data['text']
    link = raw_data['link']
    
    # A. DEDUPLICATION: Generate a unique fingerprint
    content_id = hashlib.md5(text.encode()).hexdigest()
    doc_ref = db.collection('live_notices').document(content_id)
    
    # If we already have this ID, stop immediately
    if doc_ref.get().exists: # type: ignore
        print(f"Zap! Notice '{text[:20]}...' is already in database. Skipping.")
        return

    print("🧠 New Content Detected! Waking up Gemini...")
    
    # B. INTELLIGENT SORTING
    model = genai.GenerativeModel('gemini-1.5-flash') # type: ignore
    
    prompt = f"""
    You are the CITK Campus AI. Analyze this raw notice text: "{text}"
    
    Perform these tasks:
    1. Summarize: Create a 10-word headline (Clear and Urgent).
    2. Categorize: Choose ONE ['Academic', 'Exam', 'Holiday', 'Scholarship', 'General'].
    3. Target: Who is this for? ['all', 'cse', 'civil', 'hostel', 'faculty'].
    4. Urgency: 'High' or 'Low'.
    
    Return ONLY a JSON object like:
    {{ "summary": "...", "category": "...", "target": "...", "urgency": "..." }}
    """
    
    try:
        response = model.generate_content(prompt)
        # Sanitize JSON (remove markdown backticks)
        clean_json = response.text.replace('```json', '').replace('```', '').strip()
        ai_analysis = json.loads(clean_json)
        
        # C. DATABASE INJECTION
        final_packet = {
            "title": "CITK Update",
            "body": ai_analysis['summary'],
            "original_text": text,
            "link": link,
            "category": ai_analysis['category'],
            "target": ai_analysis['target'],
            "urgency": ai_analysis['urgency'],
            "timestamp": datetime.now(),
            "source": "automated_scraper"
        }
        
        doc_ref.set(final_packet)
        print("💾 Data sorted and saved to Firestore.")
        
        # D. NOTIFICATION DISPATCH
        dispatch_notification(final_packet)
        
    except Exception as e:
        print(f"⚠️ AI Processing Failed: {e}")

# --- 4. THE BROADCASTER ---
def dispatch_notification(data):
    try:
        # Logic: If urgent, send to 'all'. If specific, send to target.
        topic = "all"
        if data['target'] != 'all':
            topic = data['target'] # e.g., 'cse'
            
        print(f"🚀 Broadcasting alert to channel: {topic}")
        
        message = messaging.Message(
            notification=messaging.Notification(
                title=f"📢 {data['category']} Alert",
                body=data['body'],
            ),
            topic=topic,
        )
        messaging.send(message)
    except Exception as e:
        print(f"⚠️ Notification Failed: {e}")

if __name__ == "__main__":
    scrape_citk()