## requirements
import requests
import re
import pandas as pd
import unicodedata
import awswrangler as wr
import matplotlib.pyplot as plt
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError
import io
import os

## normalizar nomes de estados e cidades
def norm_text(text):
    # Normaliza o texto para decompor caracteres acentuados em caracteres base + acento
    text_normalized = unicodedata.normalize('NFKD', text)
    # Remove acentos (caracteres combining marks) e converte para minúsculas
    text_without_accent = ''.join(c for c in text_normalized if not unicodedata.combining(c)).lower()
    # Define uma expressão regular para remover apóstrofos e caracteres similares
    # Inclui: ', `, ´, ’, ‘, ‛, e outros caracteres de apóstrofo
    text_without_apostrophe = re.sub(r"[`´'’‘‛ʻʼʽʾʿ]", "", text_without_accent)
    # Remove hifens '-'
    text_without_hyphens = text_without_apostrophe.replace('-', '')
    # Remove espaços entre as palavras
    text_corrected = text_without_hyphens.replace(' ', '')
    return text_corrected

# Base para os Estados => API IBGE
def getStates(url_state):
    # Fazer a requisição GET para obter os estados
    response_state = requests.get(url_state)
    # Verificar se a requisição foi bem-sucedida
    if response_state.status_code != 200:
        raise RuntimeError(f"Erro ao tentar acessar a URL {url_state}: {response_state.status_code}")
    state_data = response_state.json()

    return state_data

# Preparar os dados para o DataFrame de estados
def gatherState(state_json):
    state_data = []
    for state in state_json:
        state_id = state['id']
        state_flag = state['sigla']
        state_name = state['nome']
        state_name_norm = norm_text(state_name)
        region_flag = state['regiao']['sigla']
        region_name = state['regiao']['nome']
        region_name_norm = norm_text(region_name)
        state_data.append([state_id,
                           state_flag,
                           state_name,
                           state_name_norm,
                           region_flag,
                           region_name,
                           region_name_norm
                           ])

    # Criar o DataFrame de estados
    cols = ['state_id', 'state_flag', 'state_name', 'state_name_norm',
            'region_flag', 'region_name', 'region_name_norm']

    df_state = pd.DataFrame(state_data, columns=cols)
    return df_state

# Lista para obter todos os municipios por estado --> base IBGE
def getCities(url_base, state):
    city_by_state = []
    # Fazer a requisição GET para obter os municípios do estado
    response_cities = requests.get(url_base)
    # Verificar se a requisição foi bem-sucedida
    if response_cities.status_code != 200:
        raise RuntimeError(f"Erro ao tentar acessar a URL {url_base}: {response_cities.status_code}")

    cities = response_cities.json()
    # Preparar os dados dos municípios para o DataFrame
    for city in cities:
        city_id = city['id']
        city_name = city['nome']
        city_name_norm = norm_text(city_name)
        city_mesorregiao_name = city['microrregiao']['mesorregiao']['nome']
        city_by_state.append([city_id,
                              city_name, city_name_norm,
                              city_mesorregiao_name,
                              state])

    return city_by_state

def gatherCity(url_base, df_states):
    cities_data = []

    # Iterar sobre cada estado e buscar seus municípios
    for state_flag in df_states['state_flag']:
        url = f"{url_base}/{state_flag}/municipios"
        ibge_cities = getCities(url, state_flag)
        cities_data.extend(ibge_cities)

    cols = ['city_id', 'city_name', 'city_name_norm', 'city_mesorregiao_name', 'state_flag']
    df_city = pd.DataFrame(cities_data, columns=cols)
    df_cities = df_city.merge(df_states, on='state_flag')
    return df_cities

#write parquet in S3
# Especificar o caminho no S3 onde o arquivo Parquet será salvo
def writeS3(df, file_path):
    print (file_path)

    # Gravando o DataFrame em Parquet no S3
    try:
        wr.s3.to_parquet(
            df=df,
            path=file_path,
            dataset=True,
            mode="overwrite"  # Opções: overwrite, append
        )
    except Exception as e:
        raise RuntimeError(f"Erro ao tentar gravar {file_path} no AWS S3 - error {e}")

#plot de cidades por estado
def plot(df_city):
    # Contando a quantidade de cidades por estado
    cities_per_state = df_city.groupby('state_flag')['city_id'].count()
    # Ordenando de maior para menor
    cities_per_state = cities_per_state.sort_values(ascending=False)
    # Plot com gráfico de barras
    plt.figure(figsize=(10, 4))
    ax = cities_per_state.plot(kind='bar')

    # Adicionando o total nas barras
    for index, value in enumerate(cities_per_state):
        plt.text(index, value + 0.1, str(value), ha='center', va='bottom')

    plt.title('Quantidade de Cidades por Estado (Ordenado de Maior para Menor)')
    plt.xlabel('Estado')
    plt.ylabel('Quantidade de Cidades')
    plt.xticks(rotation=0)
    # Removendo a marcação do eixo Y
    ax.yaxis.set_ticks([])
    # Ajustar o box da figura para **diminuir a área de plotagem** (aumentando as margens)
    plt.tight_layout()
    # Criar um buffer em memória usando BytesIO
    buffer = io.BytesIO()
    # Salvar o gráfico no buffer de bytes com o formato PNG
    plt.savefig(buffer, format='png')
    buffer.seek(0)  # Movendo o ponteiro para o início do buffer
    return buffer

def sendSlack(buffer):
    # Acessar o token e o ID do canal do Slack a partir das variáveis de ambiente
    slack_token = os.getenv("SLACK_TOKEN")
    channel_id = os.getenv("SLACK_CHANNEL")
    client = WebClient(token=slack_token)

    try:
        # Usando files_upload_v2() para enviar o arquivo diretamente do buffer para o Slack
        response = client.files_upload_v2(
            channels=[channel_id],  # Substitua pelo nome do seu canal ou ID de usuário
            file=buffer,  # O buffer sendo diretamente passado como arquivo
            filename="cities_per_state.png",  # Nome do arquivo enviado
            title="Gráfico de Cidades por Estado",
            initial_comment="Aqui está o gráfico da quantidade de cidades por estado."
        )
        print("Gráfico enviado com sucesso!")
    except SlackApiError as e:
        print(f"Erro ao enviar o arquivo para o Slack: {e} - {e.response['error']}, response")
    finally:
        buffer.close()  # Fechar o buffer

#Pipeline final
def pipeline():

    # Estados
    url_base = "https://servicodados.ibge.gov.br/api/v1/localidades/estados"
    ibge_states_json = getStates(url_base)
    df_states = gatherState(ibge_states_json)

    #Cidades
    df_city = gatherCity(url_base, df_states)

    # write on S3
    file_path = "s3://holiday-br/bronze/cities_raw.parquet"
    writeS3(df_city, file_path)

    file_path = "s3://holiday-br/bronze/states_raw.parquet"
    writeS3(df_states, file_path)

    #plot and send to slack
    buffer = plot(df_city)
    sendSlack(buffer)

# Chamada principal
if __name__ == "__main__":
    try:
        pipeline()
    except Exception as e:
        print (e)

    exit(0)



