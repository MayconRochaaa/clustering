import pandas as pd
import sqlalchemy
import os
from sklearn import tree
from sklearn import ensemble
from sklearn import model_selection
from sklearn import metrics
from sklearn import preprocessing
from sklearn.naive_bayes import MultinomialNB
import matplotlib.pyplot as plt

#diretorios
BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)) )) #Pega o endereço da pasta mãe (OLIST-ML-MODELS-MAIN)
DATA_DIR = os.path.join(BASE_DIR, 'data') #Cria o caminho para pasta "data" a partir da endereço da pasta mãe
SRC_DIR = os.path.join(BASE_DIR, 'scr') #Cria o caminho para pasta "src" a partir da endereço da pasta mãe
SQL_DIR = os.path.join(SRC_DIR, 'sql') #Cria o caminho para pasta "sql" a partir da endereço da pasta src
MODEL_DIR = os.path.join(BASE_DIR, 'models')

#Cria conexão com o banco
engine = sqlalchemy.create_engine("sqlite:///" + os.path.join(DATA_DIR, 'olist.db'))

#Le a ABT
abt = pd.read_sql_table('tb_abt_churn', engine)

#Separa a ABT 2 tempos: a base out of time e o restante que de fato serão utilizadas na parte de treino e teste
df_oot = abt[abt["dt_ref"] == abt["dt_ref"].max()].copy() #filtrando base out of time 
df_oot.reset_index(drop=True, inplace=True)
df_abt = abt[abt["dt_ref"] < abt["dt_ref"].max()].copy() #filtrando base abt


#Modelagem

target = 'flag_churn' #Variavel target
to_remove = ['dt_ref', 'seller_city', 'seller_id', target] #variaveis que não serão consideradas  nos ajustes

features = df_abt.columns.tolist() #Lista com todas variaveis

for f in to_remove: #Remove as variaveis listadas em to_remove
    features.remove(f)


cat_features = df_abt[features].dtypes[df_abt[features].dtypes == 'object'].index.tolist() #Variaveis categoricas
num_features = list(set(features)-set(cat_features)) #Variaveis numericas

#Separando treino e teste
X = df_abt[features] #Matriz de features, ou variavéis
y = df_abt[target] #Vetor da resposta, ou target




#Separa a base de treino e de teste
X_train, X_test, y_train, y_test = model_selection.train_test_split(X,
                                                                    y,
                                                                   test_size=0.2,
                                                                   random_state=1999)

#Reseta os indices de X, pois temos variaveis categoricas e numericas juntas
X_train.reset_index(drop=True, inplace=True)
X_test.reset_index(drop=True, inplace=True)

#Trata as variaveis catgoricas, treinando elas com o OneHotEncoder
onehot = preprocessing.OneHotEncoder(sparse=False, handle_unknown='ignore')
onehot.fit(X_train[cat_features]) #Treina o onehot

onehot_df = pd.DataFrame(onehot.transform(X_train[cat_features]),
                         columns=onehot.get_feature_names_out(cat_features))

onehot_df_test = pd.DataFrame(onehot.transform(X_test[cat_features]), 
                              columns = onehot.get_feature_names_out(cat_features))

onehot_df_oot = pd.DataFrame(onehot.transform(df_oot[cat_features]), 
                              columns = onehot.get_feature_names_out(cat_features))

#Defina as variaveis de treinamento e de teste após o one-hot
df_train = pd.concat([X_train[num_features], onehot_df], axis=1) 
features_fit = df_train.columns.tolist()
df_train = df_train.values #Treino


df_predict = pd.concat([X_test[num_features], onehot_df_test], axis=1)
df_predict = df_predict.values #Teste

df_oot_predict = pd.concat([df_oot[num_features], onehot_df_oot], axis=1)
df_oot_predict = df_oot_predict.values

#Variaveis de teste e treino criadas agora podemos prosseguir para a modelagem

#Modelo DecisionTree
clf = tree.DecisionTreeClassifier(min_samples_leaf=100)
clf.fit(df_train,y_train)

#--------------------------------------------------------------------
y_train_pred = clf.predict(df_train) #calcula a predição
y_train_proba = clf.predict_proba(df_train) #calcula a probabilidade

acc_train = metrics.accuracy_score(y_train,y_train_pred)
roc_train = metrics.roc_curve(y_train, y_train_proba[:,1])
auc_train = metrics.roc_auc_score(y_train, y_train_proba[:,1]) #area abaixo da curva ROC

#--------------------------------------------------------------------
y_test_pred = clf.predict(df_predict)
y_test_proba = clf.predict_proba(df_predict)

acc_test = metrics.accuracy_score(y_test,y_test_pred)
roc_test = metrics.roc_curve(y_test, y_test_proba[:,1])
auc_test = metrics.roc_auc_score(y_test, y_test_proba[:,1]) 

#--------------------------------------------------------------------
oot_pred = clf.predict(df_oot_predict)
oot_proba = clf.predict_proba(df_oot_predict)

acc_oot = metrics.accuracy_score(df_oot[target],oot_pred)
roc_oot = metrics.roc_curve(df_oot[target], oot_proba[:,1])
auc_oot = metrics.roc_auc_score(df_oot[target], oot_proba[:,1]) 


result_clf = {'Base Treino':[acc_train, auc_train], 'Base Teste':[acc_test, auc_test], 'Base OOT':[acc_oot,auc_oot]}
result_clf_df = pd.DataFrame(data=result_clf, index=["Acuracia","Score ROC"])


#Plot Decision Tree
plt.figure(1)
plt.plot(roc_train[0], roc_train[1]); plt.plot(roc_test[0], roc_test[1]); plt.plot(roc_oot[0], roc_oot[1])
plt.xlabel('1 - Especificidade'); plt.ylabel('Sensibilidade'); plt.title('Curva ROC Decision Tree')
plt.legend([f"Treino TREE: {auc_train}", f"Test TREE: {auc_test}", f"OOT TREE: {auc_oot}"], facecolor="white", edgecolor="black")
plt.grid()
plt.show(1)

print(result_clf_df)

#Modelo RandomForest
rf = ensemble.RandomForestClassifier(n_estimators=350,min_samples_leaf=150)
rf.fit(df_train,y_train)

#--------------------------------------------------------------------
y_train_pred_rf = rf.predict(df_train)
y_train_proba_rf = rf.predict_proba(df_train) #calcula a probabilidade random forest

acc_train_rf = metrics.accuracy_score(y_train,y_train_pred_rf)
roc_train_rf = metrics.roc_curve(y_train, y_train_proba_rf[:,1])
auc_train_rf = metrics.roc_auc_score(y_train, y_train_proba_rf[:,1]) #area abaixo da curva ROC


#--------------------------------------------------------------------
y_test_pred_rf = rf.predict(df_predict)
y_test_proba_rf = rf.predict_proba(df_predict)

acc_test_rf = metrics.accuracy_score(y_test,y_test_pred_rf)
roc_test_rf = metrics.roc_curve(y_test, y_test_proba_rf[:,1])
auc_test_rf = metrics.roc_auc_score(y_test, y_test_proba_rf[:,1]) 


#--------------------------------------------------------------------
oot_pred_rf = rf.predict(df_oot_predict)
oot_proba_rf = rf.predict_proba(df_oot_predict)

acc_oot_rf = metrics.accuracy_score(df_oot[target],oot_pred_rf)
roc_oot_rf = metrics.roc_curve(df_oot[target], oot_proba_rf[:,1])
auc_oot_rf = metrics.roc_auc_score(df_oot[target], oot_proba_rf[:,1]) 


result_rf = {'Base Treino':[acc_train_rf, auc_train_rf], 'Base Teste':[acc_test_rf, auc_test_rf], 'Base OOT':[acc_oot_rf,auc_oot_rf]}
result_rf_df = pd.DataFrame(data=result_rf, index=["Acuracia","Score ROC"])

#threshold = 0.5
#y_pred = (oot_proba_rf[:,1] > threshold).astype('float')
conmat=metrics.confusion_matrix(df_oot[target], oot_pred_rf[:,1])
disp = metrics.ConfusionMatrixDisplay(conmat)
disp.plot()
plt.show()

#Plot RF
plt.figure(2)
plt.plot(roc_train_rf[0], roc_train_rf[1]); plt.plot(roc_test_rf[0], roc_test_rf[1]); plt.plot(roc_oot_rf[0], roc_oot_rf[1])
plt.xlabel('1 - Especificidade'); plt.ylabel('Sensibilidade'); plt.title('Curva ROC Random Forest')
plt.legend([f"Treino RF: {auc_train_rf}", f"Test RF: {auc_test_rf}", f"OOT RF: {auc_oot_rf}"], facecolor="white", edgecolor="black")
plt.grid()
plt.show(2)
print(result_rf_df)

#Fazendo o predict -------------------------------------------------------------------

""" df_abt_onehot = pd.DataFrame(onehot.transform( abt[cat_features]),
                             columns = onehot.get_feature_names_out(cat_features))
df_abt_predict = pd.concat( [abt[num_features], df_abt_onehot], axis = 1)
df_abt_predict = df_abt_predict.values

abt['score_churn'] = clf.predict_proba( df_abt_predict)[:,1]
print(abt['score_churn'])

abt_score = abt[['dt_ref','seller_id', 'score_churn']] """
#abt_score.to_sql('tb_churn_score', engine, index=False, if_exists='replace')


#Salvando o modelo

""" model_data = pd.Series({
     'num_features': num_features,
     'cat_features': cat_features,
     'onehot': onehot,
     'features_fit': features_fit,
     'model': clf,
     'acc_train': acc_train,
     'acc_test': acc_test,
     'acc_oot': acc_oot
 })
model_data.to_pickle(os.path.join(MODEL_DIR, 'arvore_decisao.pkl')) """




#Ajustando o modelo de arvore
# clf = tree.DecisionTreeClassifier(min_samples_leaf=100)
# clf.fit(X_train,y_train)

# y_train_pred = clf.predict(X_train)
# y_train_prob = clf.predict_proba(X_train)
# print('Acuracia Treino', metrics.accuracy_score(y_train,y_train_pred))
# print('AUC Treino', metrics.roc_auc_score(y_train,y_train_prob[:,1]),'\n')

# y_test_pred = clf.predict(X_test)
# y_test_prob = clf.predict_proba(X_test)
# print('Acuracia Teste', metrics.accuracy_score(y_test,y_test_pred))
# print('AUC Teste', metrics.roc_auc_score(y_test,y_test_prob[:,1]),'\n')

# y_oot_pred = clf.predict(df_oot[features])
# y_oot_prob = clf.predict_proba(df_oot[features])
# print('Acuracia OOT', metrics.accuracy_score(df_oot[target],y_oot_pred))
# print('AUC OOT', metrics.roc_auc_score(df_oot[target],y_oot_prob[:,1]))
