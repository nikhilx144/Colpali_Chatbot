# Start with a lightweight standard Python image
FROM python:3.10-slim

# Install Pandoc, a system dependency
RUN apt-get update && apt-get install -y pandoc && rm -rf /var/lib/apt/lists/*

# Set up the working directory
WORKDIR /app

# Create directories your app needs
RUN mkdir doc tts

# Copy the requirements file
COPY requirements.txt .

# --- IMPORTANT: Install the smaller CPU-only version of Torch first ---
RUN pip install torch --no-cache-dir --index-url https://download.pytorch.org/whl/cpu

# Install the rest of the Python packages
RUN pip install --no-cache-dir -r requirements.txt

# Copy all your application code into the container
COPY . .

# Expose the port Streamlit runs on
EXPOSE 8501

# Define the command to start your Streamlit app
CMD ["streamlit", "run", "main.py", "--server.port=8501", "--server.address=0.0.0.0"]