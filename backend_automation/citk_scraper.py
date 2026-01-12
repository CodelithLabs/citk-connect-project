import os
import time
import json
import requests
import hashlib
import mimetypes
import base64
from bs4 import BeautifulSoup
import firebase_admin
from firebase_admin import credentials, firestore, messaging
import google.generativeai as genai
from urllib.parse import urlparse

# ==========================================
# ⚙️ CONFIGURATION
# ==========================================
TARGET_URL = "https://cit.ac.in/pages-notices-all"
temp_filename = "temp_live_doc"

# Initialize Firebase
if not firebase_admin._apps:
    # Decode the Secret Key from GitHub Environment
    firebase_key_b64 = os.environ.get('FIREBASE_JSON_BASE64')
    if firebase_key_b64:
        decoded_key = base64.b64decode(firebase_key_b64)
        cred_dict = json.loads(decoded_key)
        cred = credentials.Certificate(cred_dict)
        firebase_admin.initialize_app(cred)
    else:
        print("⚠️ Local Mode: Using service-account.json")
        cred = credentials.Certificate("backend_automation/service-account.json")
        firebase_admin.initialize_app(cred)

db = firestore.client()

# Initialize Gemini
genai.configure(api_key=os.environ.get("GEMINI_API_KEY")) # type: ignore

# ==========================================
# 🛠️ HELPER FUNCTIONS
# ==========================================

def clean_url(base, path):
    path = str(path).strip()
    if path.startswith('http'): return path
    if not path.startswith('/'): path = '/' + path
    return base + path

def get_file_hash(filepath):
    hasher = hashlib.md5()
    with open(filepath, 'rb') as f:
        buf = f.read()
        hasher.update(buf)
    return hasher.hexdigest()

def check_if_exists(file_hash):
    """Checks Firestore to see if we already processed this file hash."""
    docs = db.collection('live_notices').where('file_hash', '==', file_hash).limit(1).get()
    return len(docs) > 0

def find_best_attachment_link(notice_page_url):
    """Smart Selector logic from God Mode."""
    try:
        response = requests.get(notice_page_url, headers={'User-Agent': 'Mozilla/5.0'}, timeout=15)
        soup = BeautifulSoup(response.text, 'html.parser')
        
        candidates = []
        for a in soup.find_all('a', href=True):
            href = str(a['href'])
            # Filter for likely documents
            if any(ext in href.lower() for ext in ['.pdf', '.jpg', '.jpeg', '.png', 'uploads/']):
                # Ignore common junk
                if any(x in href.lower() for x in ['logo', 'banner', 'footer', 'brochure']):
                    continue
                full_link = clean_url("https://cit.ac.in", href)
                candidates.append(full_link)
        
        # Return the last valid link found in the content area
        if candidates: return candidates[-1]
    except:
        pass
    return None

def analyze_with_gemini(filepath):
    """Uploads file to Gemini and gets structured JSON."""
    print("      🧠 Waking up Gemini Vision...")
    try:
        mime_type, _ = mimetypes.guess_type(filepath)
        if not mime_type: mime_type = "application/pdf"

        # Explicitly ignore type check for dynamic library imports
        sample_file = genai.upload_file(path=filepath, display_name="Live Notice", mime_type=mime_type) # type: ignore
        
        # Wait for processing
        wait_count = 0
        while sample_file.state.name == "PROCESSING":
            time.sleep(1)
            sample_file = genai.get_file(sample_file.name) # type: ignore
            wait_count += 1
            if wait_count > 60: return None

        model = genai.GenerativeModel(model_name="gemini-1.5-flash") # type: ignore
        
        prompt = """
        Analyze this college notice. Extract strictly valid JSON:
        {
            "is_important": boolean,
            "category": "Exam/Academic/Scholarship/Hostel/General",
            "target_audience": ["CSE", "Civil", "All", "Faculty", etc],
            "summary": "15-word summary",
            "entities": {
                "event_date": "YYYY-MM-DD",
                "semester": "String"
            }
        }
        """
        response = model.generate_content([sample_file, prompt])
        genai.delete_file(sample_file.name) # type: ignore
        
        clean_json = response.text.replace('```json', '').replace('```', '').strip()
        return json.loads(clean_json)
    except Exception as e:
        print(f"      ❌ AI Error: {e}")
        return None

def send_push_notification(data):
    """Sends a notification to the app users."""
    try:
        # Default topic is 'all', specific topics can be added later
        topic = "all"
        message = messaging.Message(
            notification=messaging.Notification(
                title=f"📢 {data['ai_analysis']['category']} Update",
                body=data['ai_analysis']['summary'],
            ),
            data={
                "click_action": "FLUTTER_NOTIFICATION_CLICK",
                "notice_id": data['id']
            },
            topic=topic,
        )
        messaging.send(message)
        print(f"      🚀 Notification sent to topic: {topic}")
    except Exception as e:
        print(f"      ⚠️ Push failed: {e}")

# ==========================================
# 🚀 MAIN ROBOT LOGIC
# ==========================================
def run_live_scraper():
    print("🕵️ Starting CITK Live Scraper (God Mode Edition)...")
    
    try:
        response = requests.get(TARGET_URL, headers={'User-Agent': 'Mozilla/5.0'}, timeout=20)
        soup = BeautifulSoup(response.text, 'html.parser')
        rows = soup.find_all('tr')
    except Exception as e:
        print(f"❌ Connection Error: {e}")
        return

    # Check only top 5 notices to keep it fast
    for row in rows[1:6]:
        cols = row.find_all('td')
        if len(cols) < 3: continue
            
        title = cols[1].get_text(strip=True)
        pub_date = cols[3].get_text(strip=True) if len(cols) > 3 else "Unknown"
        
        link_tag = row.find('a', href=True)
        if not link_tag: continue
        
        web_page_link = clean_url("https://cit.ac.in", link_tag['href'])
        
        print(f"\n🔍 Checking: {title[:40]}...")

        # 1. Find PDF
        real_file_url = find_best_attachment_link(web_page_link)
        
        if real_file_url:
            # 2. Download to Temp
            try:
                # Get extension
                parsed = urlparse(real_file_url)
                ext = os.path.splitext(parsed.path)[1]
                if not ext: ext = ".pdf"
                local_path = temp_filename + ext

                r = requests.get(real_file_url, headers={'User-Agent': 'Mozilla/5.0'}, timeout=20)
                if r.status_code == 200:
                    with open(local_path, 'wb') as f:
                        f.write(r.content)
                    
                    # 3. Calculate Hash
                    file_hash = get_file_hash(local_path)
                    
                    # 4. Check Database (Deduplication)
                    if check_if_exists(file_hash):
                        print("      ✅ Already in database. Skipping.")
                    else:
                        print("      🆕 New Notice detected! Analyzing...")
                        
                        # 5. Gemini Analysis
                        ai_data = analyze_with_gemini(local_path)
                        
                        if ai_data:
                            # 6. Save to Firestore
                            doc_id = hashlib.md5(title.encode()).hexdigest()
                            record = {
                                "id": doc_id,
                                "file_hash": file_hash,
                                "meta": { "title": title, "date": pub_date, "url": real_file_url },
                                "ai_analysis": ai_data,
                                "timestamp": firestore.SERVER_TIMESTAMP # type: ignore
                            }
                            
                            db.collection('live_notices').document(doc_id).set(record)
                            print("      💾 Saved to Firestore.")
                            
                            # 7. Notify Users
                            send_push_notification(record)
                        
                    # Cleanup
                    if os.path.exists(local_path): os.remove(local_path)
            except Exception as e:
                print(f"      ⚠️ Processing Error: {e}")

if __name__ == "__main__":
    run_live_scraper()