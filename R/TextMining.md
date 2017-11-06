# Text Mining de los textos de los artículos

Lo que vamos a realizar aquí es convertir en valores numéricos el texto de los artículos. Básicamente vamos a convertir cada artículo en un vector de palabras que lo identifiquen.

Primero llevamos a cabo una limpieza de aquellas palabras que están consideradas como palabras vacias ó '**stopwords**'. Estos son palabras como los artículos, pronombres, conjunciones,...

A continuación se procede a normalizar la infomación. Para ello:
* Se convierten todos los datos a minúsculas,
* Se eliminan los saltos de línea y tabulaciones.
* Se quitan los acentos.
* Se eliminan aquellos síbolos especiales y números.
* Se eliminan los dobles espacios. 
* Se eliminan los espacios antes y después del artículo.

Si después de realizar esta limpieza nos hemos quedado sin texto, se elimina el registro. 

Se lleva a cabo una lematización de las palabras. Para ello se utiliza la función *****wordStem***** que incluye el paquete **Snowball**. La lematización consiste en la reducción de las palabras a su raiz, recortando el final de la palabra siguiendo unos patrones definidos. La lematización no tiene en cuenta el significado de las palabras, solo se basa en patrones de expresiones regulares.

Para realizar la vectorización de palabras, se utiliza el paquete **tm**, generando primero un corpus diccionario con el conjunto completo de palabras y después generando una matriz de documentos y términos.

Esto se realiza tanto para las palabras como para los lemas. Esto permite realizar los entrenamientos con un conjunto u otro y comparar cual de ellos proporciona más información.

Así las sentencias que se ejecutan son:

    corpus <- Corpus(VectorSource(cmm_palabras))
    dtm <- DocumentTermMatrix(corpus, control=list(removePunctuation=TRUE, bounds=list(global=c(10, Inf))))

Al generar la matriz de documentos - términos, le indicamos que tenga en cuenta solo aquellas palabras que aparecen al menos 10 veces en el conjunto de documentos. De esta forma eliminamos palabras (que pueden ser errores de escritura) que no van a aportar valor. De igual manera se podría limitar aquellas palabras que aparecen más de un número determinado de veces.

Además nos guardamos la información del cojunto de palabras que forman el vocabulario completo. Esto es necesario ya que el vector de palabras tiene una estructura concreta (cada columna del vector representa a una palabra concreta) y cuando se realice el entrenamiento, validación y predicción será necesario generar las mismas estructuras para que el sistema funcione correctamente.

Como información del vocabulario, el siguiente diagrama muestra el conjunto de palabras más utilizado en el conjunto de artículos (en formato wordCloud y generado con la función *****wordCloud***** del paquete del mismo nombre:

![palabras más frecuentes](https://github.com/jluqueor/predictor_jornada_liga/blob/master/img/wordCloud_todas.JPG)

