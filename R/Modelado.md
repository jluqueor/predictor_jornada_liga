# Entrenamiento del modelo y evaluación

Llegamos al momento de entrenar el modelo y evaluar que tal funciona. No prentende esta guía ser una guía exhaustiva de modelado, solo indicar algunos puntos que hay que tener en cuenta a la hora de entrenar un modelo.

Se utiliza el paquete ***xgboost*** como herramienta para realizar el entrenamiento.

Tenemos un target que puede tomar tres valores diferentes. Se trata por tanto de un modelo de clasificación multiclase. El objetivo que vamos a utilizar será '**multi:softmax**'.




Los resultados obtenidos no son muy buenos. Se puede trabajar más sobre los datos, seleccionando restricciones de palabras, incorporando más datos (de otros diarios). Como detalle, si analizamos las palabras que más aparecen en los artículos de los equipos, agrupando los comentarios por el tipo de evolución que han tenido (es decir, agrupando los comentarios que han precedido a derrota, un empate o una victoria, independientemente del equipo, tenemos las siguientes ***nubes de palabras***:

![wordCloud sobre artículos agrupados por evolución de los equipos](https://github.com/jluqueor/predictor_jornada_liga/blob/master/img/WordCloudEvolucion.JPG)

No parece existir mucha diferencia entre un conjunto de palabras y los otros...

