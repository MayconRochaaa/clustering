import os
import pandas as pd
import sqlalchemy

#Caso haja um servidor
'''user = ''
psw = ''
host = ''
port = ''
str_connection = 'mysql+pymysql:///{user}:{psw}@{host}:{port}' '''

#Endereços dos objetos e subpastas
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(''))) #Pega o endereço da pasta mãe (ProjetoOlist)
DATA_DIR = os.path.join(BASE_DIR, 'data') #Cria o caminho para pasta "data" a partir da endereço da pasta mãe

#Encontrando os arquivos de dados

#Pega apenas os itens terminados em csv 
files_names = [i for i in os.listdir(DATA_DIR) if i.endswith('.csv')]


#Abrindo a conexão com o banco
str_connection = 'sqlite:///{path_to_data}'
str_connection = str_connection.format(path_to_data=os.path.join(DATA_DIR, 'ecommerce.db')) 
connection = sqlalchemy.create_engine(str_connection) #Faz a conexão com o banco de dados

#Para cada arquivo é realizado uma inserção no banco
#for i in files_names:  #passa o caminho de cada arquivo CSV
    #df_tmp = pd.read_csv(os.path.join(DATA_DIR,i))
    #table_name = 'tb_'+i.strip('.csv').replace('-','_')
    #df_tmp.to_sql(table_name,connection)

chunk_size = 100000  # Número de linhas por lote
for file_name in files_names:
    table_name = 'tb_' + file_name.strip('.csv').replace('-', '_')
    for chunk in pd.read_csv(os.path.join(DATA_DIR, file_name), chunksize=chunk_size):
        chunk.to_sql(table_name, connection, if_exists='append')
