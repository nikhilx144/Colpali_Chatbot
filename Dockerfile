# Step 1: Start with a lightweight standard Python image
FROM python:3.10-slim

# Step 2: Install Pandoc, a system dependency needed by pypandoc
RUN apt-get update && apt-get install -y pandoc && rm -rf /var/lib/apt/lists/*

# Step 3: Set up the working directory inside the container
WORKDIR /app

# Step 4: Create directories your app needs to store files
RUN mkdir doc tts

# Step 5: Copy the requirements file first to leverage Docker's caching
COPY requirements.txt .

# Step 6: Install the Python packages
RUN pip install --no-cache-dir -r requirements.txt

# Step 7: Copy all your application code into the container
COPY . .

# Step 8: Expose the port Streamlit runs on
EXPOSE 8501

# Step 9: Define the command to start your Streamlit app
CMD ["streamlit", "run", "main.py", "--server.port=8501", "--server.address=0.0.0.0"]