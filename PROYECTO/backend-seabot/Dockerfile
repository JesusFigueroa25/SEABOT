# Imagen base con Python
FROM python:3.11-slim

# Evita que Python genere archivos .pyc
ENV PYTHONDONTWRITEBYTECODE 1
# Evita que el output se bufee (útil para logs)
ENV PYTHONUNBUFFERED 1

# Establecer directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiar requirements.txt e instalar dependencias
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar archivo de credenciales del NLP (tu archivo real)
COPY fiery-chess-471215-k9-d39d8968a3b9.json /app/google-credentials.json

# Variable de entorno que Google NLP usa para autenticación
ENV GOOGLE_APPLICATION_CREDENTIALS="/app/google-credentials.json"

# Copiar todo el proyecto
COPY . .

# Establecer variable de entorno para puerto
ENV PORT=8080

# Expone el puerto de FastAPI
EXPOSE 8080

# Comando para ejecutar la aplicación
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
