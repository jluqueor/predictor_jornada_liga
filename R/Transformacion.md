# Transformación de datos capturados del diario Marca

En el proceso de captura se han recuperado dos conjuntos de datos de la competición de liga de primera división española:
## Equipos y resultados de cada jornada.
Información de los puntos obtenidos por cada equipo a lo largo de las 38 jornadas de cada temporada. Tenemos cada temporada en un fichero diferente. La estructura de cada uno de estos ficheros es:

    > resultados[resultados$i==1,c("teamsName", "temporada", "i", "points", "fecha")]
         teamsName temporada i points      fecha
    1    Barcelona   2016_17 1      3 2016-08-21
    2    R. Madrid   2016_17 1      3 2016-08-21
    3      Sevilla   2016_17 1      3 2016-08-21
    4   Las Palmas   2016_17 1      3 2016-08-21
    5    Deportivo   2016_17 1      3 2016-08-21
    6     Sporting   2016_17 1      3 2016-08-21
    7      Leganés   2016_17 1      3 2016-08-21
    8       Alavés   2016_17 1      1 2016-08-21
    9     Atlético   2016_17 1      1 2016-08-21
    10     Granada   2016_17 1      1 2016-08-21
    11      Málaga   2016_17 1      1 2016-08-21
    12     Osasuna   2016_17 1      1 2016-08-21
    13  Villarreal   2016_17 1      1 2016-08-21
    14    Athletic   2016_17 1      0 2016-08-21
    15       Eibar   2016_17 1      0 2016-08-21
    16       Celta   2016_17 1      0 2016-08-21
    17    Espanyol   2016_17 1      0 2016-08-21
    18    Valencia   2016_17 1      0 2016-08-21
    19 R. Sociedad   2016_17 1      0 2016-08-21
    20       Betis   2016_17 1      0 2016-08-21

Datos correspondientes a la jornada 1 de la temporada 2016 - 2017. por cada temporada disponemos de **760** filas x **6** columnas.

## Articulos escritos durante toda la temporada
Por cada equipo, la lista de articulos que se han escrito, identificando la fecha en la que se publicaron:

![view(recortes)](https://github.com/jluqueor/predictor_jornada_liga/blob/master/img/viewRecortes.JPG)

La siguiente tabla contiene el detalle del número de artículos recuperados por cada temporada:

| Temporada | Artículos |
|-----------|-----------|
|  2012-13  |    32.860 |
|  2013-14  |    28.948 |
|  2014-15  |    31.031 |
|  2015-16  |    48.245 |
|  2016-17  |    59.132 |
|  2017-18  |    17.550 |

El número de artículos escritos crece año a año. En la temporada 2016-17 practicamente duplica el número de artículos escritos en la temporada 2012-13.

## Objetivo de la transformación de los datos.
Se trata de formatear los datos de manera que se puedan utilizar para entrenar un modelo que luego nos permita realizar predicciones sobre nuevos datos.

El planteamiento es tratar de predecir el resultado que va a obtener un equipo de futbol, analizando los artículos escritos sobre este equipo en los días anteriores a la celebración de la jornada.

Para ello tendremos que tener los articulos de un equipo correspondientes a los días previos a una jornada y, para el entrenamiento, información del resultado (target).

Disponemos de los puntos que cada equipo ha obtenido en cada jornada. Para analizar la evolución, se ha optado primero por formar una matriz con un registro por equipo y añadiendo como nuevas columnas la información de los puntos obtenidos en cada jornada:

![Matriz Jornadas](https://github.com/jluqueor/predictor_jornada_liga/blob/master/img/matrizJornadas.JPG)

Para calcular la evolución, analizamos que ha hecho cada equipo en cada jornada, es decir, si ganó, empató o perdió.

Para realizar este cálculo, compararemos el resultado de la jornada con el resultado de la jornada anterior:
* Si tiene los mismos puntos, el equipo perdió el partido. Consideramos este caso como una evolución negativa y le daremos el valor -1
* Si tiene un punto más, el equipo empató el partido. En este caso consideramos que la evolución es estable y le daremos un valor de 0.
* Si tiene 3 puntos más, el equipo ganó el partido. En este caso el equipo tiene una evolucion positiva y le daremos el valor +1.

![Evolución](https://github.com/jluqueor/predictor_jornada_liga/blob/master/img/capturaEvolucion.JPG)

Por otro lado, los textos de los artículos escritos sobre cada equipo, los tenemos en varias filas (una por artículo) y disponemos de varios días de información. 

Primero agrupamos todos los artículos escritos para un equipo en un día, concatenando los textos uno a continuación del otro:

    articulos <- aggregate(articulo ~ teamsPath + fecha, recortes, paste, collapse=" ")

El siguiente paso es identificar a que jornada corresponde cada artículo. Esto lo hacemos en base a la fecha de publicación y las fechas de la jornada anterior y la jornada siguiente:

![Selección artículos](https://github.com/jluqueor/predictor_jornada_liga/blob/master/img/articulosJornada.JPG)

Agrupamos los artículos de un equipo que corresponden a la misma jornada en un único registro de manera similar a como lo realizamos antes:

    articulosJornada <- aggregate(articulo ~ teamsPath + jornada, articulos, paste, collapse=" ")

Una vez terminado el proceso, descargamos la información a un tablón con la estructura:

![Tablón de datos](https://github.com/jluqueor/predictor_jornada_liga/blob/master/img/viewTablon.JPG)

Ya tenemos la información preparada para el modelado, solo nos falta convertir en algo numérico el texto de los artículos.
