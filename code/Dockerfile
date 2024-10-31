# Usar uma imagem base do Python 3.10
FROM python:3.10-slim

# Definir o autor da imagem
LABEL author="Sandra"

# Copiar o arquivo requirements.txt para o container
COPY requirements.txt .

# Instalar as dependências do Python listadas em requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copiar o código da aplicação para o container (pode incluir outros arquivos necessários)
COPY . .

# Definir a variável de ambiente para não gerar bytecode compilado (.pyc)
ENV PYTHONDONTWRITEBYTECODE=1

# Definir a variável de ambiente para não usar o buffer de saída (importante para logs em tempo real)
ENV PYTHONUNBUFFERED=1

# Comando para rodar o script
CMD ["python", "estados.py"]
