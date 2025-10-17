import streamlit as st
import os
from sidebar import configure_sidebar
from file_handler import handle_file_upload
from model_loader import load_and_index_model
from ui import run_interface

# Page setup
st.set_page_config(layout="wide")
st.title("Colpali Based Multimodal RAG App")

# --- START: API Key Handling Logic ---
# Check session state first, then environment variables
if 'api_key' not in st.session_state:
    st.session_state.api_key = os.environ.get('OPENAI_API_KEY', '')

# If no key is found, ask the user for it
if not st.session_state.api_key:
    st.session_state.api_key = st.text_input("Enter your OpenAI API Key to start", type="password")

# Only proceed if we have an API key
if st.session_state.api_key:
    # Sidebar config
    sidebar_config = configure_sidebar()

    # File handling
    file_path = handle_file_upload()

    # Main interface logic
    if file_path:
        rag_model = load_and_index_model(sidebar_config['model'], sidebar_config['device'], file_path)
        # Pass the API key to the UI function
        run_interface(rag_model, sidebar_config['vlm'], st.session_state.api_key)
    else:
        st.info("Upload a document from the left sidebar to get started.")
else:
    st.warning("Please provide your OpenAI API Key to use the application.")
# --- END: API Key Handling Logic ---