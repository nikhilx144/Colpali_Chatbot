import os
import streamlit as st
import tempfile
import shutil
import pypandoc

# Directory to save uploaded/converted documents
upload_dir = os.path.join(os.getcwd(), "doc")
os.makedirs(upload_dir, exist_ok=True)

def handle_file_upload():
    uploaded_file = st.session_state.get("file")
    if uploaded_file:
        file_name = uploaded_file.name
        file_ext = os.path.splitext(file_name)[-1].lower()

        file_path = os.path.join(upload_dir, file_name)
        
        # Remove existing file if present
        if os.path.exists(file_path):
            try:
                os.remove(file_path)
            except PermissionError:
                st.error("File is in use. Please close it and try againn.")
                return None

        # Save the uploaded file
        with open(file_path, "wb") as f:
            f.write(uploaded_file.getbuffer())

        # Handle Word (.docx) files: convert to PDF
        if file_ext == ".docx":
            with tempfile.NamedTemporaryFile(delete=False, suffix=".pdf") as tmp_pdf:
                try:
                    # Download pandoc if not available
                    # pypandoc.download_pandoc()
                    
                    # Convert to PDF
                    pypandoc.convert_file(file_path, "pdf", outputfile=tmp_pdf.name)
                    
                    # Copy converted PDF to upload_dir
                    final_pdf_path = os.path.join(upload_dir, os.path.splitext(file_name)[0] + ".pdf")
                    shutil.copy(tmp_pdf.name, final_pdf_path)
                    
                    return final_pdf_path
                except Exception as e:
                    st.error(f"Failed to convert .docx to .pdf: {e}")
                    return None

        # For PDF files, return path as is
        elif file_ext == ".pdf":
            return file_path

        else:
            st.error("Unsupported file format. Please upload a .pdf or .docx file.")
            return None

    return None