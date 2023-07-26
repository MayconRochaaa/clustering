import pandas as pd
import sqlalchemy
import os
import argparse

#Cria a ABT
BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)) )) #Pega o endereço da pasta mãe (OLIST-ML-MODELS-MAIN)
DATA_DIR = os.path.join(BASE_DIR, 'data') #Cria o caminho para pasta "data" a partir da endereço da pasta mãe
SRC_DIR = os.path.join(BASE_DIR, 'scr') #Cria o caminho para pasta "src" a partir da endereço da pasta mãe
SQL_DIR = os.path.join(SRC_DIR, 'sql') #Cria o caminho para pasta "sql" a partir da endereço da pasta src

engine = sqlalchemy.create_engine("sqlite:///" + os.path.join(DATA_DIR, 'olist.db'))

with open (os.path.join(SQL_DIR,'criacao_abt.sql'),'r') as open_file:
    query = open_file.read()

for i in query.split(";")[:-1]:
    engine.execute(i)