import json
import os
from dotenv import load_dotenv
from supabase import create_client, Client
import google.generativeai as genai

# Load API keys
load_dotenv()
supabase: Client = create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_KEY"))
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

def ingest_handbook():
    # Open your perfectly formatted JSON
    with open('handbook_final.json', 'r', encoding='utf-8') as file:
        handbook_data = json.load(file)

    print(f"Starting ingestion of {len(handbook_data)} sections...")

    for item in handbook_data:
        # 1. Extract the core text strings
        chapter = item.get("chapter_title", "")
        section = item.get("section_title", "")
        sub_section = item.get("sub_section", "")
        content = item.get("body_text", "")
        
        # Skip empty entries safely
        if not content or not content.strip():
            continue
            
        # 2. Build the ultimate Context String for Gemini to embed
        # We include the sub-section here so the math vector captures the highly specific topic
        text_to_embed = f"Chapter: {chapter}\nSection: {section}\nSub-Section: {sub_section}\n\n{content}"
        
        # 3. Generate the 768-dimension math vector using Gemini
        try:
            result = genai.embed_content(
                model="models/gemini-embedding-001",
                content=text_to_embed,
                task_type="retrieval_document",
                title="USLS Student Handbook"
            )
            vector_embedding = result['embedding']
        except Exception as e:
            print(f"Embedding failed for {section}: {e}")
            continue

        # 4. Map EVERY piece of your JSON into the database metadata
        # We safely check the nested "metadata" object using .get()
        nested_meta = item.get("metadata", {})
        
        db_metadata = {
            "chapter_id": item.get("chapter_id"),
            "chapter_title": chapter,
            "section_id": item.get("section_id"),
            "section_title": section,
            "sub_section": sub_section,
            "content_type": item.get("content_type"),
            "page_approx": nested_meta.get("page_approx"),
            "institution": nested_meta.get("institution")
        }

        # 5. Insert into Supabase
        try:
            supabase.table('article_embeddings').insert({
                "content": content,
                "metadata": db_metadata,
                "embedding": vector_embedding
            }).execute()
            print(f"Saved: {chapter} -> {sub_section}")
        except Exception as e:
            print(f"Database insert failed for {section}: {e}")

    print("Complete! The GuideU memory bank is fully loaded.")

if __name__ == "__main__":
    ingest_handbook()