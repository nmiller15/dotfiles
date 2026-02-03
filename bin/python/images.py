import os
import re
import argparse
import boto3
import re
from botocore.exceptions import NoCredentialsError

parser = argparse.ArgumentParser(description="Process a folder of markdown files to upload images to S3")
parser.add_argument("folder_path", type=str, help="The folder containing the markdown files to process.")
parser.add_argument("bucket_name", type=str, help="The name of the S3 bucket to upload images to.")
parser.add_argument("attachments_directory", type=str, help="The directory containing the attachments.")

args = parser.parse_args()

BUCKET_NAME = args.bucket_name
# BUCKET_NAME = 'nolanmiller-image-hosting'
MD_DIRECTORY = args.folder_path
# MD_DIRECTORY = '/Users/nolanmiller/Library/CloudStorage/GoogleDrive-nolan.miller77@gmail.com/My Drive/Vault/0 - Inbox'
ATTACHMENTS_DIRECTORY = args.attachments_directory
# ATTACHMENTS_DIRECTORY = '/Users/nolanmiller/Library/CloudStorage/GoogleDrive-nolan.miller77@gmail.com/My Drive/Vault/attachments'

# IMAGE_PATH = '/Users/nolanmiller/Library/CloudStorage/GoogleDrive-nolan.miller77@gmail.com/My Drive/Vault/3 - Resources/pictures/headshot.jpg'
# IMAGE_KEY = 'headshot.jpg'

s3 = boto3.client('s3')


def parse_markdown_image(markdown_image):
    # Patterns for the two types of markdown images
    pattern_double_brackets = r'!\[\[(.*?)\]\]'
    pattern_markdown_image = r'!\[(.*?)\]\((.*?)\)'
    
    # Check if it matches the double bracket pattern
    double_bracket_match = re.match(pattern_double_brackets, markdown_image)
    if double_bracket_match:
        # Extract the path and remove the extension for the title
        path = double_bracket_match.group(1)
        # Remove the file extension and extraneous characters for title
        title = re.sub(r'\.[a-zA-Z0-9]+$', '', path)
        print(f"Title: {title}, Path: {path}")
        return {
            'title': title,
            'path': path
        }
    
    # Check if it matches the markdown image pattern
    markdown_image_match = re.match(pattern_markdown_image, markdown_image)
    if markdown_image_match:
        # Extract title from [] and path from ()
        title = markdown_image_match.group(1)
        path = markdown_image_match.group(2)
        
        # Check if the path is an AWS S3 URL and skip if it is
        if re.search(r'https?://.*\.s3\..*\.amazonaws\.com/', path):
            print(f"Skipping AWS image: {path}")
            return None  # Skip this image
        
        print(f"Title: {title}, Path: {path}")
        return {
            'title': title,
            'path': path
        }
    
    # If no pattern matched, return None
    return None

def upload_to_s3(parsed_image):
    image_path = parsed_image['path']
    absolute_path = os.path.join(ATTACHMENTS_DIRECTORY, image_path)
    image_key = os.path.basename(image_path)

    print(f"Upload file: {absolute_path} to S3 bucket: {BUCKET_NAME} with key: {image_key}")

    try:
        s3.upload_file(absolute_path, BUCKET_NAME, image_key)
        print(f"Image uploaded to S3: {image_key}")

        image_uri = f"https://{BUCKET_NAME}.s3.amazonaws.com/{image_key}"
        image_uri = image_uri.replace(' ', '+')
        print("Image uploaded successfully.")
        print("Image URI:", image_uri)
        return image_uri

    except FileNotFoundError:
        print("The file was not found")
        return None
    except NoCredentialsError:
        print("Credentials not available")
        return None

def search_markdown_files(directory, pattern):
    # Compile the regular expression pattern for better performance
    regex = re.compile(pattern)
    
    # Loop through all files in the given directory
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.md'):
                file_path = os.path.join(root, file)
                
                # Open and read the markdown file
                with open(file_path, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                    
                # Search for the pattern in each line
                for line_number, line in enumerate(lines, start=1):
                    matches = regex.findall(line)
                    if matches:
                        new_line = line  # Start with the original line
                        for match in matches:
                            print(f"Match: {match} in file {file_path}.")
                            parsed_image = parse_markdown_image(match)
                            if parsed_image:
                                image_uri = upload_to_s3(parsed_image)
                                if image_uri:
                                    # Construct the replacement markdown image
                                    replacement = f"![{parsed_image['title']}]({image_uri})"
                                    print(f"Replacing {match} with {replacement}")
                                    # Replace the specific match in the line
                                    new_line = new_line.replace(match, replacement)
                        
                        # Update the line in lines after all replacements
                        lines[line_number - 1] = new_line

                # Write the updated lines back to the file
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.writelines(lines)
             
REGEX_PATTERN = r'!\[\[.*?\]\]'
search_markdown_files(MD_DIRECTORY, REGEX_PATTERN)
