# Purpose: Analyze PDFs, text, and website data to create AI-ready database
# ===========================================================================

"""
AI Data Processor for CITK
Analyzes notices, events, and other data to create structured database
"""

import json
import re
import hashlib
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional
import PyPDF2
import requests
from bs4 import BeautifulSoup

class CITKDataProcessor:
    """Process and analyze CITK data for AI consumption"""
    
    def __init__(self, gemini_api_key: str):
        self.api_key = gemini_api_key
        self.categories = [
            "Academic", "Scholarship", "Event", "Exam", 
            "Admission", "Recruitment", "Holiday", "General"
        ]
        self.audiences = [
            "B. Tech", "M. Tech", "PhD", "Faculty", "All Students"
        ]
    
    def analyze_notice_with_ai(self, text: str, url: str, date: str) -> Dict:
        """Use Gemini to analyze notice content"""
        import google.generativeai as genai
        
        genai.configure(api_key=self.api_key)
        model = genai.GenerativeModel('gemini-2.0-flash-exp')
        
        prompt = f"""
Analyze this CITK notice and extract structured information:

Notice Text:
{text}

Date: {date}
URL: {url}

Respond in JSON format with:
{{
    "is_important": true/false,
    "category": "Academic/Scholarship/Event/Exam/Admission/Recruitment/Holiday/General",
    "target_audience": ["B. Tech", "M. Tech", "PhD", "Faculty", "All Students"],
    "summary": "Brief 1-2 sentence summary",
    "entities": {{
        "event_date": "YYYY-MM-DD or null",
        "deadline": "YYYY-MM-DD or null",
        "semester": "Which semester(s) affected or null",
        "department": "Which department(s) or null",
        "location": "Where if mentioned or null"
    }},
    "keywords": ["key", "words", "for", "search"]
}}

Only return valid JSON, nothing else.
"""
        
        try:
            response = model.generate_content(prompt)
            # Parse JSON from response
            json_text = response.text.strip()
            # Remove markdown code blocks if present
            if json_text.startswith('```'):
                json_text = json_text.split('```')[1]
                if json_text.startswith('json'):
                    json_text = json_text[4:]
            
            return json.loads(json_text)
        except Exception as e:
            print(f"AI Analysis failed: {e}")
            return self._fallback_analysis(text)
    
    def _fallback_analysis(self, text: str) -> Dict:
        """Fallback analysis if AI fails"""
        return {
            "is_important": "exam" in text.lower() or "important" in text.lower(),
            "category": "General",
            "target_audience": ["All Students"],
            "summary": text[:150] + "..." if len(text) > 150 else text,
            "entities": {},
            "keywords": []
        }
    
    def extract_text_from_pdf(self, pdf_path: str) -> str:
        """Extract text from PDF file"""
        try:
            with open(pdf_path, 'rb') as file:
                reader = PyPDF2.PdfReader(file)
                text = ""
                for page in reader.pages:
                    text += page.extract_text()
                return text
        except Exception as e:
            print(f"PDF extraction failed: {e}")
            return ""
    
    def scrape_notice_from_url(self, url: str) -> Dict:
        """Scrape notice content from URL"""
        try:
            response = requests.get(url, timeout=10)
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Extract text content
            text = soup.get_text(separator=' ', strip=True)
            
            return {
                "url": url,
                "text": text[:5000],  # Limit to 5000 chars
                "scraped_at": datetime.now().isoformat()
            }
        except Exception as e:
            print(f"Scraping failed: {e}")
            return {"url": url, "text": "", "error": str(e)}
    
    def process_notice(self, 
                      title: str, 
                      date: str, 
                      url: str,
                      pdf_path: Optional[str] = None,
                      text_content: Optional[str] = None) -> Dict:
        """Process a single notice and create structured data"""
        
        # Extract content
        if pdf_path:
            content = self.extract_text_from_pdf(pdf_path)
        elif text_content:
            content = text_content
        elif url.endswith('.pdf'):
            # Download and extract PDF
            content = self._download_and_extract_pdf(url)
        else:
            # Scrape from URL
            scraped = self.scrape_notice_from_url(url)
            content = scraped.get('text', '')
        
        # Generate unique IDs
        notice_id = hashlib.md5(f"{title}{date}".encode()).hexdigest()
        file_hash = hashlib.md5(content.encode()).hexdigest()
        
        # AI Analysis
        ai_analysis = self.analyze_notice_with_ai(
            f"Title: {title}\n\nContent: {content[:3000]}", 
            url, 
            date
        )
        
        return {
            "id": notice_id,
            "file_hash": file_hash,
            "meta": {
                "title": title,
                "date": date,
                "url": url,
                "created_at": datetime.now().isoformat()
            },
            "content": content[:1000],  # Store excerpt
            "ai_analysis": ai_analysis
        }
    
    def _download_and_extract_pdf(self, url: str) -> str:
        """Download PDF from URL and extract text"""
        try:
            response = requests.get(url, timeout=30)
            temp_path = Path("temp_notice.pdf")
            temp_path.write_bytes(response.content)
            text = self.extract_text_from_pdf(str(temp_path))
            temp_path.unlink()
            return text
        except Exception as e:
            print(f"PDF download failed: {e}")
            return ""
    
    def batch_process_notices(self, notices: List[Dict]) -> List[Dict]:
        """Process multiple notices"""
        processed = []
        for i, notice in enumerate(notices):
            print(f"Processing {i+1}/{len(notices)}: {notice.get('title', 'Unknown')}")
            try:
                result = self.process_notice(
                    title=notice['title'],
                    date=notice['date'],
                    url=notice['url'],
                    text_content=notice.get('text')
                )
                processed.append(result)
            except Exception as e:
                print(f"Failed to process notice: {e}")
                continue
        
        return processed