import os 
import pandas as pd
import sqlalchemy
import argparse
import datetime

parser = argparse.ArgumentParser()
parser.add_argument("--dt_ref",help="Data referencia para safra a ser predita: YYYY-MM-DD")
args = parser.parse_args()

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)) )) #Pega o endereço da pasta mãe (OLIST-ML-MODELS-MAIN)
DATA_DIR = os.path.join(BASE_DIR, 'data') #Cria o caminho para pasta "data" a partir da endereço da pasta mãe
SRC_DIR = os.path.join(BASE_DIR, 'scr') #Cria o caminho para pasta "src" a partir da endereço da pasta mãe
SQL_DIR = os.path.join(SRC_DIR, 'sql') #Cria o caminho para pasta "sql" a partir da endereço da pasta src
PREDICT_DIR = os.path.join(BASE_DIR, 'python')
MODELS_DIR = os.path.join(BASE_DIR,'models')

print("Importando modelo...", end="")
model = pd.read_pickle(os.path.join(MODELS_DIR,'model_churn.pkl'))
print("ok.")

print("Abrindo conecão com banco de dados...", end="")
con = sqlalchemy.create_engine("sqlite:///" + os.path.join(DATA_DIR, 'olist.db'))
print("ok.")

print("Importando dados...",end="")
df = pd.read_sql_query(f"SELECT * FROM tb_book_sellers WHERE dt_ref = '{args.dt_ref}';",
                       con)
print("ok.")


print('Preparando dados para aplicar o modelo...')
df_onehot = pd.DataFrame(model['onehot'].transform(df[model['cat_features']]),
                         columns = model['onehot'].get_feature_names_out(model['cat_features']))

df_full = pd.concat([df[model['num_features']],df_onehot],axis=1)[model['features_fit']]

print('ok.')

print("Criando score...",end="")
df['score'] = model['model'].predict_proba(df_full)[:,1]
print(df[['seller_id','score']])
print('ok.')

print("Enviando os dados para o banco de dados...", end="")

df_score = df[["dt_ref","seller_id","score"]].copy()
df_score["dt_atualizacao"] = datetime.datetime.now()

df_score.to_sql("tb_churn_score", con, if_exists='replace', index=False)

print('ok.')
