
# Use Python 3.10 slim image

FROM python:3.10-slim



WORKDIR /app



# Copy your code

COPY . .



# Install dependencies (Make sure you have gradio in requirements.txt)

RUN pip install --no-cache-dir -r requirements.txt



# ----------------------------------------------------------------

# CRITICAL GRADIO SETTINGS FOR CLOUD RUN

# ----------------------------------------------------------------

# 1. Listen on 0.0.0.0 (External), not 127.0.0.1 (Localhost)

ENV GRADIO_SERVER_NAME="0.0.0.0"



# 2. Listen on port 8080 (Cloud Run's default), not 7860

ENV GRADIO_SERVER_PORT=8080



# Expose the port (Documentation only, but good practice)

EXPOSE 8080



# Run the app directly with Python

# CHANGE 'app.py' to your actual filename if different

CMD ["python", "app.py"]

