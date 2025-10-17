import os
import torch
import gc
import streamlit as st
from byaldi import RAGMultiModalModel

# Cache the model so it doesn't reload every time
@st.cache_resource
def load_rag_model(model_name, device):
    return RAGMultiModalModel.from_pretrained(model_name, verbose=10, device=torch.device(device))

# Cache document indexing (ignoring model hashing by renaming param with "_")
@st.cache_data
def build_index(_rag_model, path):
    _rag_model.index(
        input_path=path,
        index_name="image_index",
        store_collection_with_index=True,
        overwrite=True
    )
    gc.collect()

# Utility to load model and index document
def load_and_index_model(model_name, device, file_path):
    rag_model = load_rag_model(model_name, device)
    with st.spinner("Indexing the document..."):
        build_index(rag_model, file_path)  # rag_model is passed to _rag_model
    st.success(f"✅ Uploaded: {os.path.basename(file_path)}")
    return rag_model