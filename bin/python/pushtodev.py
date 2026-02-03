import os
import json
import re
import yaml
import requests
from collections import OrderedDict
import argparse

success = "Did not post."

parser = argparse.ArgumentParser(description="Process a folder of markdown files to push to DEV.to")
parser.add_argument("folder_path", type=str, help="The folder containing the markdown files to process.")

def load_api_key():
    """Reads the API key from the .json file in the directory."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    config_path = os.path.join(script_dir, "keys.json")
    try: 
        with open(config_path, 'r', encoding='utf-8') as config_file:
            config = json.load(config_file)
            return config.get("devto_key")
    except Exception as e:
        print(f"Error loading API key: {e}")
        return None

# Define constants
args = parser.parse_args()
print(args)
FOLDER_PATH = args.folder_path
DEV_API_URL = "https://dev.to/api/articles"
API_KEY = load_api_key()
if not API_KEY:
    raise ValueError("API key is missing or could not be loaded. Check keys.json for a devto_key.")

def read_front_matter(file_path):
    """Reads the front matter from a file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            content = file.read()
            if content.startswith('---'):
                parts = content.split('---', 2)
                front_matter = yaml.safe_load(parts[1])
                body = parts[2].strip()
                return front_matter, body
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
    return None, None

def find_article_id_by_title(title, headers):
    """Fetches all articles from DEV.to and returns the ID of the article with the matching title."""
    try:
        print(f"GET: {DEV_API_URL}/me/published")
        response = requests.get(f"{DEV_API_URL}/me/published", headers=headers)
        if response.status_code == 200:
            articles = response.json()
            for article in articles:
                if article["title"] == title:
                    print(f"Match found for article: {article['title']}")
                    return article["id"]
        else:
            print(f"Failed to fetch articles: {response.status_code} {response.text}")
    except Exception as e:
        print(f"Error fetching articles: {e}")
    return None

def post_to_dev(article_data, front_matter):
    """Posts or updates an article to DEV.to."""
    headers = {
        "api-key": API_KEY,
        "Content-Type": "application/json"
    }
    try:
        if "dev_id" in front_matter and front_matter["dev_id"]:
            update_url = f"{DEV_API_URL}/{front_matter['dev_id']}"
            print(f"PUT: {update_url}")
            response = requests.put(update_url, json={"article": article_data}, headers=headers)
            success = "Performed PUT operation."
        else:
            print(f"POST: {DEV_API_URL}")
            response = requests.post(DEV_API_URL, json={"article": article_data}, headers=headers)
            success = "Performed POST operatiion."

        if response.status_code in [200, 201]:
            article_id = response.json().get("id")
            print(f"Article {article_id} - '{article_data['title']}' successfully {'updated' if 'dev_id' in article_data else 'posted'}.")
            return article_id
        elif response.status_code == 422:
            print(f"POST RESPONSE: {response.status_code}: {response.reason}")
            print(f"Article '{article_data['title']}' already exists. Attempting to find its ID...")
            article_id = find_article_id_by_title(article_data["title"], headers)
            if article_id:
                print(f"Updating article with ID: {article_id}")
                update_url = f"{DEV_API_URL}/{article_id}"
                response = requests.put(update_url, json={"article": article_data}, headers=headers)
                success = "Performed PUT operation."
                if response.status_code == 200:
                    print(f"Article '{article_data['title']}' updated successfully.")
                    return article_id
            else:
                print(f"Could not find article ID for '{article_data['title']}' to update.")
        else:
            print(f"Failed to post/update article '{article_data['title']}': {response.status_code} {response.text}")
        print(f"{success}")
    except Exception as e:
        print(f"Error posting/updating article: {e}")
    return None

def generate_canonical_url(title):
    slug = re.sub(r"[^a-z0-9-]", "", title.lower().replace(" ", "-"))
    return f"https://nolanmiller.me/posts/{slug}"

def write_front_matter(file_path, front_matter, body):
    """Writes the front matter and body back to the file while preserving front matter order."""
    try:
        # Manually serialize the front matter to avoid unwanted YAML syntax issues
        front_matter_str = "---\n"
        for key, value in front_matter.items():
            # Handle boolean values properly (keep them lowercase)
            if isinstance(value, bool):
                value = 'true' if value else 'false'
            
            # Handle lists (e.g., for 'tags')
            elif isinstance(value, list):
                value = "[" + ", ".join(f'"{item}"' for item in value) + "]"

            # Handle nested dictionaries (convert to string format)
            elif isinstance(value, dict):
                value = "\n".join(f"    {k}: {v}" for k, v in value.items())
            
            # Add the formatted key-value pair to the front matter string
            front_matter_str += f"{key}: {value}\n"
        
        front_matter_str += "---\n"

        # Write the updated content to the file
        with open(file_path, 'w', encoding='utf-8') as file:
            file.write(front_matter_str + body)
            print(f"Updated front matter in {file_path}")
    except Exception as e:
        print(f"Error writing front matter to {file_path}: {e}")

def process_folder(folder_path):
    """Processes all files in the folder and updates the 'dev' field and writes the DEV.to ID in the front matter."""
    for file_name in os.listdir(folder_path):
        file_path = os.path.join(folder_path, file_name)
        if os.path.isfile(file_path):
            try:
                front_matter, body = read_front_matter(file_path)
                if front_matter and front_matter.get("dev") == False and front_matter.get("draft") == False:
                    print(f"Building article for DEV.to: {file_name}")
                    article_data = {
                        "title": front_matter.get("title", "Untitled"),
                        "body_markdown": body,
                        "published": True,
                        "series": front_matter.get("series"),
                        "canonical_url": generate_canonical_url(front_matter.get("title", "")),
                        "description": front_matter.get("description"),
                        "tags": front_matter.get("tags"),
                    }
                    dev_id = post_to_dev(article_data, front_matter)
                    if dev_id:
                        front_matter["dev"] = True
                        front_matter["dev_id"] = dev_id
                        write_front_matter(file_path, front_matter, body)
                        print(f"Updated 'dev' field to True and added 'dev_id' for {file_name}.")
            except Exception as e:
                print(f"Error processing {file_path}: {e}")

process_folder(FOLDER_PATH)
print(f"DEV.to publishing script exited.")
