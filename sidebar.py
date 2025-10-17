import streamlit as st
import torch

def configure_sidebar():
    st.sidebar.header("Configuration Options")
    model = st.sidebar.selectbox("Colpali Model", ["vidore/colpali", "vidore/colpali-v1.2"])
    device = st.sidebar.selectbox("Device", ["cpu", "cuda"])
    if device == "cuda" and not torch.cuda.is_available():
        st.sidebar.warning("CUDA is not available. Switching to CPU.")
        device = "cpu"
    vlm = "gpt-4o"
    st.sidebar.header("📄 Select File")
    # sidebar.py
    # sidebar.py (update file uploader line)
    st.sidebar.file_uploader("Upload your PDF / Word Document", type=["pdf", "docx"], key="file")
    st.sidebar.header("🛠️ Select Task")
    task = st.sidebar.radio("Choose action", ["Summarize", "Chat with Document"], key="task")
    return {"model": model, "device": device, "vlm": vlm, "task": task}