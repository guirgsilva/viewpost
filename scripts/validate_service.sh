#!/bin/bash

echo "Validating service..."

# Variáveis de configuração
MAX_ATTEMPTS=30
SLEEP_TIME=10
ENDPOINT="http://localhost/health"

# Função para verificar o serviço
check_service() {
    curl -s -f "$ENDPOINT" > /dev/null
    return $?
}

# Loop de verificação
for ((i=1; i<=$MAX_ATTEMPTS; i++)); do
    echo "Waiting for application to start... ($i/$MAX_ATTEMPTS)"
    
    if check_service; then
        echo "Service is running!"
        exit 0
    fi
    
    sleep $SLEEP_TIME
done

echo "Service validation failed after $MAX_ATTEMPTS attempts"
exit 1