import requests
from bs4 import BeautifulSoup
import json

def scrape_citk_notices():
    """Scrape latest notices from CITK website"""
    url = "https://cit.ac.in/notices"
    
    try:
        response = requests.get(url)
        soup = BeautifulSoup(response.content, 'html.parser')
        
        notices = []
        # Adjust selectors based on actual website structure
        for item in soup.select('.notice-item'):
            title = item.select_one('.title').text.strip()
            date = item.select_one('.date').text.strip()
            link = item.select_one('a')['href']
            
            notices.append({
                'title': title,
                'date': date,
                'url': f"https://cit.ac.in{link}"
            })
        
        return notices
    except Exception as e:
        print(f"Scraping failed: {e}")
        return []

if __name__ == "__main__":
    notices = scrape_citk_notices()
    with open('scraped_notices.json', 'w') as f:
        json.dump(notices, indent=2, fp=f)
    print(f"Scraped {len(notices)} notices")