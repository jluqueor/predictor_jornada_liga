# Predicción resultados jornada de liga

Este proyecto incluye los procesos necesarios para llevar a cabo un proceso de predicción. Desde la descarga de datos al proceso de modelado y visualización de los resultados.

El proceso completo esta realizado con código R. Visualmente los procesos que se llevan a cabo son los siguientes:

![Proceso](https://github.com/jluqueor/predictor_jornada_liga/blob/master/img/Proceso.JPG)

## Objetivos

Este proyecto tiene varios objetivos:
* Determinar si se puede predecir el resultado de cada equipo que participa en la competición de fútbol jornada a jornada basándonos en los artículos publicados en medios especializados. 
* Publicar una guía general que describa el tratamiento a realizar con los datos y que sirva de ayuda al lector.
* Una guía sencilla de como tratar información textual y como convertirla en variables numéricas de las que extraer información.

## Proceso

### Selección

El primer paso realizado es la identicación de las fuentes de datos que nos proporcionarán información. Hay mucha información publicada de diferentes medios. Como punto de partida y como ejemplo, se opta por analizar la información que el diario ''marca'' publica en su web. Para llevar a cabo análisis predictivos es necesario disponer de información histórica que permita entrenar modelos y ''marca'' habilita desde su web a la consulta de su hemeroteca. 

La información identificada en este diario es la siguiente: 

#### Articulos publicados por fecha

Se puede acceder a los articulos publicados en cada fecha desde el año 2009. La estructura de los enlaces incorpora la fecha y acceso a subsecciones de cada deportes (especialmente de de fútbol que nos interesa en este caso), y permite la selección de la categoría a estudiar:

![Hemeroteca Marca](https://github.com/jluqueor/predictor_jornada_liga/blob/master/img/hemerotecaMarca.JPG)

(Imagen de la página de marca. Se incluye aquí a modo demostrativo y para motivos educativos. Puede acceder a la web original desde este enlace '[Hemeroteca Marca](http://www.marca.com/hemeroteca/2017/)').

Esto es especialmente interesante ya que nos permite acceder a la información específica que queremos estudiar.

#### Resultados de cada jornada

Tiene un enlace específico donde proporciona las estadísticas de resultado de cada jornada y categoría. Esto facilita la obtención de la situación de cada equipo al finalizar cada jornada, así como los equipos que conforman cada temporada, fechas de cada jornada, número de jornadas de la temporada consultada, enlaces a las estadísticas de las otras jornadas de la temporada...

![Clasificación jornada](https://github.com/jluqueor/predictor_jornada_liga/blob/master/img/clasificacionJornada.JPG)

Este mismo análisis se puede realizar con otras publicaciones de manera que se capture más información. 

### Obtención

La obtención de los datos requiere de un análisis detallado de las páginas que queremos rastrear. Hay que tener cuidado tambien porque el modo en que se presenta la información puede diferir entre varias consultas. La obtención se ha realizado capturando datos desde 2011 hasta el día de hoy. Se han detectado hasta tres cambios de formato en las páginas durante estos años. 

El proceso de rastreo y captura suele además ser un proceso costoso en tiempo de ejecución, ya que dependemos del ancho de banda que el proveedor del servicio este dando y del número de páginas a descargar y tratar. Puede suceder que la información falle para algún día por lo que es facil que tengamos que repetir el proceso varias veces hasta conseguir el procesamiento completo. 

Se detalla en la siguiente URL el proceso realizado: ![Webscraping](https://github.com/jluqueor/predictor_jornada_liga/blob/master/R/WebScraping.md)

### Transformación

Descargada la información debemos proceder a ajustarla de modo que se ajuste al análisis que queremos realizar. En este caso queremos:
* Analizar los artículos que se publican por cada equipo una semana antes de la jornada que queremos analizar (en realidad, aquellos articulos que se han publicado después de la última jornada y antes de la jornada que queremos predecir).
* Establecer el comportamiento del equipo desde una jornada a la siguiente. Para esto analizamos la variación de puntos de cada equipo de una semana a la siguiente:
    * Si los puntos son los mismos, el equipo va a peor (no consiguió ningún punto).
    * Si solo adquirió un punto: el equipo se mantiene (empató en la jornada).
    * Si adquirió más de un punto, el equipo ha mejorado.
* Agrupar la información de cada equipo por cada jornada, texto de los artículos publicados y evolución de sus resultados en esa jornada.

En la siguiente url se detalla el proceso realizado: ![Transformación](https://github.com/jluqueor/predictor_jornada_liga/blob/master/R/Transformacion.md)


### Text Mining

En este punto pasamos a realizar el análisis del texto y generar información que sea explotable por modelos. EN este ejemplo llevaremos a cabo un análisis estadístico de las palabras utilizadas en cada artículo:
* Identificaremos el vocabulario completo que disponemos. Eliminaremos dígitos, signos de puntuación, palabras que no aporten significado. Puede simplificar el análisis el eliminar aquellas palabras que se utilizan en todos los artículos y que no proporcionan información adicional.
* Establecemos grupos de datos para entrenamiento, pruebas y validación de los modelos que generemos. El conjunto de validación lo reservaremos para permitir validar que tal se comporta el modelo final que generemos. 
* Convertiremos cada texto en un vector que represente las palabras utilizadas en los articulos referentes a cada equipo.

En la siguiente url se puede consultar el detalle de este proceso: ![Text Mining](https://github.com/jluqueor/predictor_jornada_liga/blob/master/R/TextMining.md)

### Modelado

Con los datos convertidos en información numérica y seleccionados los datos de entrenamiento, pruebas y test, iniciamos el proceso de modelado. Se ha optado por utilizar el algoritmo ''xgboost'' para hacer el modelado, pero se pueden utilizar cualquier otro tipo de modelo.

Se muestran además formas de implementar ejecuciones sucesivas de entrenamiento con diferentes parámetros de manera que se facilite la comprobación de los mejores valores para los parámetros.

En el siguiente enlace se describe el proceso realizado: ![Modelado](https://github.com/jluqueor/predictor_jornada_liga/blob/master/R/Modelado.md)

### Evaluación

La evaluación de los modelos generados puede ser más o menos compleja. Como ejemplo se muestran formas de presentar la información de manera que se pueda evaluar que tal se está comportando el modelado y hacia donde debemos adaptar los parámetros para obtener mejores resultados.

En la siguiente url se describe el proceso propuesto para la presentación de la información y algunos ejemplos prácticos (se comparte la página donde se describe el modelado): ![Evaluacion](https://github.com/jluqueor/predictor_jornada_liga/blob/master/R/Modelado.md)


