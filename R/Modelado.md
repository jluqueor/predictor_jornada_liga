# Entrenamiento del modelo y evaluación

Llegamos al momento de entrenar el modelo y evaluar que tal funciona. No prentende esta guía ser una guía exhaustiva de modelado, solo indicar algunos puntos que hay que tener en cuenta a la hora de entrenar un modelo.

## Como entrenaremos
Vamos a utilizar el paquete ***xgboost*** como herramienta para realizar el entrenamiento del modelo.

Tenemos un target que puede tomar tres valores diferentes. Se trata por tanto de un modelo de clasificación multiclase. El objetivo que vamos a utilizar será '**multi:softmax**'. El resultado que obtendremos en predicciones sobre este modelo es una clasificación. si queremos obtener probabilidades, podríamos utilizar '**multi:softprob**'.

Como métrica de evaluación del modelo, usaremos la métrica '***mlogloss***' 

Este paquete permite el re-entrenamiento de un modelo obtenido en un entrenamiento anterior. Utilizaremos esta funcionalidad para permitir capturar el resultado cada cierto número de iteraciones y realizar comprobaciones. Además los modelos obtenidos los iremos volcando a disco, de manera que no tengamos que repetir el entrenamiento si hemos detectado que un modelo anterior era mejor o poder continuar un entrenamiento desde un punto dado. 

Como modelo de ***booster*** utilizaremos '*****gbtree*****'.

## Procesar un entrenamiento
Para facilitar el entrenamiento y tuneado de los diferentes parámetros, se ha incorporado un proceso general que realiza llamadas al entrenamiento y de manera iterativa realiza comprobaciones del modelo generado, valida predicciones y almancena resultados, repetiendo el proceso tantas veces como se le indique por parámetros. 

Este proceso se ha plasmado en modo de función de manera que se pueda reutilizar el código. Veamos un poco el detalle de este proceso:

    procesaModelo <- function(X, target, strWords, cmm, condTrain, condDev, parametros, modelo=NULL, iteraciones=1, ... ) {

Recibe como parámetros:
* **X**: un data.frame con los datos que entrenamos, 
* **target**: los valores objetivos.
* **strWords**: Contiene la lista de palabras que se quieren analizar de los datos. Es el vector de palabras que se obtuvo en el proceso de text-mining y que es necesario para mantener la estructura del vector de palabras. Esto facilita que al procesar con nuevos datos, podamos asegurar que la estructura de vector que estamos usando es la misma.
* **cmm**: Estructura que contiene ***arrays*** de palabras que corresponden al texto de la fila que estamos procesando.
* **condTrain** y **condDev**: condiciones a aplicar para la selección de los datos de entrenamiento y datos de prueba recibidos en **X**, **target** y **cmm**.
* **modelo**: Modelo entrenado anteriormente y sobre el que queremos iterar nuevo entrenamiento.
* **iteraciones**: número de veces que queremos iterar el entrenamiento.
* ...
Incluye más parámetros pero que se pasan directamente al proceso de entrenamiento que llama a la función ***xgboost***.

Los pasos que se realizan son:

### Preparar datos
Se generan matrices de documentos y términos para los datos recibidos para cada uno de los grupos de datos usados (entrenamiento y prueba). Estas matrices se convierte a sparseMatrix que es el formato que admite ***xgboost*** (es un formato de matriz dispersa, que se caracteríza por ocupar menos espacio que una matrix estándar si los datos que almacena son valores 0 en su mayoría).

Por ejemplo, para los datos de entrenamiento:

    Y   <- c(0, target[condTrain])
    cmmData <-  c(paste(strWords, collapse=" "), cmm[condTrain])
    dtmData <- DocumentTermMatrix(Corpus(VectorSource(cmmData)), control=list(dictionary=strWords))
    sparseTrain <- sparseMatrix(i=dtmData$i, j=dtmData$j, x=dtmData$v, dimnames=dimnames(dtmData))

Además se normalizan los datos de manera que los rangos de aparición de cada palabra esté en el rango de [0, 1]. Primero calculamos cual es el valor máximo de cada columna (palabra):

    c <- c(1:(sparseTrain@Dim[2]))
    cMax <- sapply(c, function(j) {
       max(sparseTrain@x[(sparseTrain@p[j]+1):sparseTrain@p[j+1]])})
       
Y aplicamos la normalización sobre el conjunto de datos de la sparseMatrix que hemos generado:

    sparseTrain <- sparseTrain %*% Matrix::Diagonal(x = 1 / cMax)
    
Además nos guardamos este factor de normalización de manera que podamos recuperarlo cuando vayamos a aplicarlo sobre predicciones de nuevos datos (para uso productivo).    

Adecuamos los valores***target*** para ajustarnos a los valores de clase que admite ***xgboost*** (no admite valores negativos). Los valores que tenemos en nuestros datos son:

* -1: pierde.
*  0: empata.
*  1: gana.

Los convertimos a los valores:

* 0: pierde.
* 1: empata.
* 2: gana.

### Itera entrenamiento

Repite proceso de entrenamiento tantas veces como se indique por parámetros. 
Por cada entrenamiento del modelo, realizamos predicción tanto para los datos de entrenamiento como para los datos de prueba y evaluamos el resultado, almacenando en un fichero resumen cual ha sido el resultado.

## Como evaluar

Decidir si un resultado de modelo se comporta mejor que otro es una tarea compleja. La recomendación es fijar una métrica que será la que iremos comprobando y que nos permitirá decidir si un modelo nos está dando un mejor resultado que otro o si las iteraciones sobre un modelo mejoran el resultado.

Se incluyen cuatro ejemplos de métricas que se pueden utilizar. Algunas de las métricas descritas se utilizan para evaluar el comportamiento en modelos de resultado binario. En este caso tenemos tres posibles resultados para cada evaluación por lo que hay que establecer que validaciones se van a realizar en cada métrica.

Se considera que el resultado neutro o negativo es el caso del empate. Las situaciones en las que se gana o pierde, las consideraremos como resultados positivos.

|resultado|etiqueta|  caso  |
|---------|--------|--------|
|gana     |    2   |positivo|
|empata   |    1   |negativo|
|pierde   |    0   |positivo|

Definimos las siguientes variables:

* **true positive (TP)**: Si la predicción es positiva (0, 2) y el resultado real coincide con el valor de la etiqueta.
* **false positive (FP)**: Si la predicción es positiva (0, 2) y el resultado real no coincide con el valor de la etiqueta.
* **true negative (TN)**: Si la predicción es negativa (1) y el resultado real coincide con la etiqueta (1).
* **false negative (FN)**: Si la predicción es negativa (1) pero el resultado real no coincide con el valor de la etiqueta (0 ó 2).

Así tenemos la matriz de confusión en la que las filas indican el resultado real y las columnas la predicción:

|            |0 (pierde)|1 (empata)|2 (gana)|
|------------|----------|----------|--------|
| 0 (pierde) |    TP    |    FN    |   FP   |
| 1 (empata) |    FP    |    TN    |   FP   |
| 2 (gana)   |    FP    |    FN    |   TP   |

### Métrica precisión
Calculamos el valor de precisión como:

** Precision = (true positives) / (true positives + false positives)

    precision <- length(predice[(predice==0 & Y==0) | (predice==2 & Y==2)])/length(Y[predice==0 | predice==2])
    
La información que proporciona esta medida es la habilidad del modelo para no clasificar como positivo (predicción = 0 ó 2) un valor que es negativo.   

### Métrica recall
Calculamos el valor de recall como:

**Recall =  (true positives) / (true positives + false negatives)**

    recall <- length(predice[(predice==0 & Y==0) | (predice==2 & Y==2)])/length(Y[(Y==0 & predice==0) | (Y==2 & predice==2) | (Y==0 & predice==1) | (Y==2 & predice==1)])

La interpretación de este modelo es la habilidad del modelo de encontrar todos los ejemplos positivos.

### Métrica F1 score
Calculamos el valor de F1 score como:

**F1 = 2 * (precision * recall) / (precision + recall)**

    f1_score <- 2*(precision*recall)/(precision+recall)
    
F1 score funciona como una medida compensada entre el valor de la precisión y el recall. Permite identificar si el modelo está balanceado sobre estos valores.

### Métrica acierto:
Calculamos el porcentaje de acierto como:

    acierto <- length(predice[predice==Y])/length(Y)*100
    
## Entrenamiento y evaluación    

Primero lanzaremos un entrenamiento con los valores por defecto:

    a <- procesaModelo("X"=datos[xRandom,],
                       "target"=datos$Evolucion[xRandom],
                       "strWords"=strLemas,
                       "cmm"=cmm_lemas,
                       "condTrain"=(1:(round(nrow(datos)*0.8))),
                       "condDev"=(((round(nrow(datos)*0.8))+1):(round(nrow(datos)*0.9))),
                       parametros="random_lemas_10Rounds_1jornada",
                       iteraciones=10,
                       xNthread=10,
                       xNround=10)

Después de un tiempo de ejecución, podemos ver los resultados:

    resumen <- muestraResultados(path, xCarpeta)
    
Obteniendo los siguientes gráficos:



diferentes Recomendamos fijar una métrica que se pueda ir comprobando en cada iteración del entrenamiento 
iteración, la predicción
ara los datos de entrenamiento:


## Conclusiones 
Los resultados obtenidos no son muy buenos. Se puede trabajar más sobre los datos, seleccionando restricciones de palabras, incorporando más datos (de otros diarios). Como detalle, si analizamos las palabras que más aparecen en los artículos de los equipos, agrupando los comentarios por el tipo de evolución que han tenido (es decir, agrupando los comentarios que han precedido a derrota, un empate o una victoria, independientemente del equipo, tenemos las siguientes ***nubes de palabras***:

![wordCloud sobre artículos agrupados por evolución de los equipos](https://github.com/jluqueor/predictor_jornada_liga/blob/master/img/WordCloudEvolucion.JPG)

No parece existir mucha diferencia entre un conjunto de palabras y los otros...

