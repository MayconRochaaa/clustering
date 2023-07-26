import os
import sqlalchemy
import argparse
from datetime import datetime
from dateutil.relativedelta import relativedelta

parser = argparse.ArgumentParser()
parser.add_argument("--date_init", "-i ",help="Data Ref. Inic. da Safra. (str: YYYY-MM-DD)", type=str)
parser.add_argument("--date_end", "-e", help="Data Ref. Fim da Safra. (str: YYYY-MM-DD)", type=str)
args = parser.parse_args()

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)) )) #Pega o endereço da pasta mãe (OLIST-ML-MODELS-MAIN)
DATA_DIR = os.path.join(BASE_DIR, 'data') #Cria o caminho para pasta "data" a partir da endereço da pasta mãe
SRC_DIR = os.path.join(BASE_DIR, 'scr') #Cria o caminho para pasta "src" a partir da endereço da pasta mãe
SQL_DIR = os.path.join(SRC_DIR, 'sql') #Cria o caminho para pasta "sql" a partir da endereço da pasta src

#Definindo uma função para importar query
def import_query(path, **kwards):
    with open(path, 'r', **kwards) as file_open:
        result = file_open.read()
    return result

#Conexão com o banco de dados
def connect_db():
    return sqlalchemy.create_engine("sqlite:///"+os.path.join(DATA_DIR,"olist.db"))

con = connect_db()

#Definindo as datas de inicio e fim como variaveis
dt_end = datetime.strptime(args.date_end, "%Y-%m-%d")
dt = datetime.strptime(args.date_init, "%Y-%m-%d")

"Importando a query da tabela 'segmentos_dinamico.sql' para a variavel query"
query = import_query(os.path.join(SQL_DIR,"segmentos_dinamico.sql"))

#Laço para obter todas as safras dentro do intervalo dado (de mês em mês)
while dt <= dt_end:
    dt = dt.strftime("%Y-%m-%d")

#Caso a safra ja exista ela é deletada do banco
    try:
        print("\n Tentando resetar {dt}...".format(dt=dt), end="")
        con.execute("DELETE FROM tb_book_sellers WHERE dt_ref = '{date}' ".format(date=dt))
        print('Ok. \n')
    except:
        print('Tabela não encontrada')
        pass

#Cria a tabela no banco
    try:
        print("\n Tentando criar tabela...", end="")
        base_query = 'CREATE TABLE tb_book_sellers AS\n {query}'
        con.execute(base_query.format(query=query.format(date=dt))) 
        print('Ok. \n')
    except:
        print("\n Tabela já existente, inserindo dados de {dt}...".format(dt=dt), end="")
        base_query = 'INSERT INTO tb_book_sellers\n {query}'
        con.execute(base_query.format(query=query.format(date=dt))) 
        print('Ok. \n')

    dt = datetime.strptime( dt, "%Y-%m-%d" ) + relativedelta(months=1)
