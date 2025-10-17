import streamlit as st
from openai import OpenAI
from gtts import gTTS
from PIL import Image
from deep_translator import GoogleTranslator
from io import BytesIO
import base64
from sklearn.metrics.pairwise import cosine_similarity
from sentence_transformers import SentenceTransformer

# The main interface function now accepts the api_key
def run_interface(rag_model, vlm, api_key):
    st.subheader("🌐 Language")
    languages = {'English': 'en', 'Hindi': 'hi', 'Telugu': 'te'}
    selected_lang = st.selectbox("Translate result to:", list(languages.keys()))

    task = st.session_state["task"]
    # Pass the api_key down to the next functions
    if task == "Summarize":
        summarize_ui(rag_model, vlm, selected_lang, languages, api_key)
    elif task == "Chat with Document":
        chat_ui(rag_model, vlm, selected_lang, languages, api_key)

# Summarize function now accepts and uses the api_key
def summarize_ui(rag_model, vlm, selected_lang, languages, api_key):
    client = OpenAI(api_key=api_key) # Initialize client here
    st.markdown("### ✍️ Optional: Enter your own summary to compare")
    user_summary = st.text_area("Your summary", height=150)

    if st.button("Summarize"):
        query = "Summarize the document"
        results = rag_model.search(query, k=10, return_base64_results=True)

        response = client.chat.completions.create(
            model=vlm,
            messages=[{
                "role": "user",
                "content": [
                    {"type": "text", "text": query},
                    {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{results[0].base64}"}}
                ]
            }],
            max_tokens=400
        )
        answer = response.choices[0].message.content
        translated = GoogleTranslator(source='auto', target=languages[selected_lang]).translate(answer)

        st.markdown(f"### 📝 Generated Summary ({selected_lang})")
        st.markdown(translated)

        tts = gTTS(text=translated, lang=languages[selected_lang])
        tts.save("tts/summary_audio.mp3")
        st.audio("tts/summary_audio.mp3")

        if user_summary.strip():
            st.markdown("### 🔍 Similarity Score")
            embedder = SentenceTransformer('all-MiniLM-L6-v2')
            embeddings = embedder.encode([translated, user_summary])
            score = cosine_similarity([embeddings[0]], [embeddings[1]])[0][0]

            st.progress(int(score * 100))
            st.markdown(f"**{score:.2f} similarity between your summary and the generated one.**")
            if score > 0.8:
                st.success("✅ Highly similar")
            elif score > 0.5:
                st.info("ℹ️ Moderately similar")
            else:
                st.warning("⚠️ Low similarity – your summary might need revision.")

# Chat function now accepts and uses the api_key
def chat_ui(rag_model, vlm, selected_lang, languages, api_key):
    client = OpenAI(api_key=api_key) # Initialize client here
    query = st.text_input("💬 Ask something about the document")
    if st.button("Ask"):
        results = rag_model.search(query, k=10, return_base64_results=True)
        response = client.chat.completions.create(
            model=vlm,
            messages=[{
                "role": "user",
                "content": [
                    {"type": "text", "text": query},
                    {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{results[0].base64}"}}
                ]
            }],
            max_tokens=400
        )
        answer = response.choices[0].message.content
        translated = GoogleTranslator(source='auto', target=languages[selected_lang]).translate(answer)

        st.markdown(f"### 💡 Answer ({selected_lang})")
        st.markdown(translated)

        tts = gTTS(text=translated, lang=languages[selected_lang])
        tts.save("tts/response_audio.mp3")
        st.audio("tts/response_audio.mp3")

        image_data = base64.b64decode(results[0].base64)
        image = Image.open(BytesIO(image_data))
        st.image(image, caption="Relevant Page", use_container_width=True)