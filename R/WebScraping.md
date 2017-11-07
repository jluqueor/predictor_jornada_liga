# Web Scraping páginas del diario Marca

Proceso de rastreo de las páginas de **Marca** para obtener de su hemeroteca información de artículos publicados e información de estadísticas por jornada.

Hay multitud de sitios web y modos de realizar '***webscraping***'. Para realizar el proceso desde código R, en este proyecto utilizamos el paquete *****rvest***** y nos hemos ayudado de las descripciones que se realizan sobre este paquete en esta página: [beginners guide](https://www.analyticsvidhya.com/blog/2017/03/beginners-guide-on-web-scraping-in-r-using-rvest-with-hands-on-knowledge/).

Para realizar '***webscraping***' se requiere tener unos conocimientos mínimos del lenguaje **HTML** y de como se codifican las páginas web. Normalmente, no queremos la totalidad de información que aparece en una página web y es necesario identificar que partes de la misma queremos sacar. Para el caso de las páginas de **Marca**, nos interesa la información de los diferentes artículos que se incluyen en el diario en cada día de su hemeroteca, concretamente los enlaces a los artículos completos, siendo necesario analizar la estructura de los artículos completos para poder sacar exclusivamente la información del texto de los artículos.

Para ayudar a realizar esta tarea, en la documentación del propio paquete de *****rvest***** aconsejan utilizar un selector de **CSS**, en concreto recomienda usar el ***plugin*** [selector gadget](http://selectorgadget.com/) que se incorpora como elemento del navegador **Chrome**.

![Selector CSS](https://github.com/jluqueor/predictor_jornada_liga/blob/master/img/webScrapingSelectorCSS.JPG).

También ayuda explorar el código de la página web, por ejemplo con la funcionalidad **inspeccionar** del navegador **Chrome**:

![Inspeccionar](https://github.com/jluqueor/predictor_jornada_liga/blob/master/img/InspeccionarElementoChrome.JPG)

La estructura de las páginas de marca que contiene la información que nos interesa, es la siguiente:

![Estructura Hemeroteca Marca](https://github.com/jluqueor/predictor_jornada_liga/blob/master/img/estructuraHemerotecaMarca.JPG)

Para capturar la información se ha generado el módulo *****WebScraping.R*****. A continuación se describe detalladamente el proceso de webscraping correspondiente a la captura de información de estadísticas de cada jornada. El resto del código se puede descargar del proyecto.

    # -----------------------------------------------------------------------------------------------
    # getResults:
    # ==========
    # Busqueda de equipos que participan en una temporada, las fechas de cada jornada  y los 
    # resultados obtenidos por cada equipo
    # -----------------------------------------------------------------------------------------------
    getResults <- function(vYear) {
      temporada <- paste(vYear, substring(as.double(vYear)+1, 3, 4), sep="_")
      url <- paste("http://www.marca.com/estadisticas/futbol/primera/" , temporada, "/jornada_1/", sep="")

Se Formatea la ruta **http** correspondiente a la temporada que queremos consultar.

      doc <- read_html(url)

La función *****read_html***** del paquete *****rvest***** lee la información de una página web y la guarda formateada con la estructura **html** de origen.

      lJornadas <- html_attrs(html_children(html_children(html_children(html_nodes(doc, '.navegacion-jornadas')))))
      
En el proceso de análisis de la página de estadísticas, hemos detectado que el área que contiene la información de jornadas está etiquetada con la clase **.navegacion-jornadas**. Una vez posicionados en este elemento, navegamos hasta la etiqueta **<a>** que se encuentra a tres niveles de profundidad. El resultado que obtenemos es una lista con las jornadas que incluye esta temporada.

      calendario <- NULL
      for (jornada in lJornadas) {
        calendario <- rbind(calendario, jornada["title"])
      }
  
Recorremos la lista de jornadas capturando la fecha de la misma.

      charCalen <- strsplit(calendario, split=" ")

Cada elemento de charCalen tiene la forma ***<dia1> **"y"** <dia2> <mes>***.
Tomamos el valor de ***<dia2>*** (3 posición):
    
      vDays <- unlist(lapply(charCalen, function(x) {x[3]}))

Tomamos el valor de ***<mes>*** (4 posición)
    
      vMonths <- unlist(lapply(charCalen, function(x) {x[4]}))

Convertimos la información capturada en datos tipo fecha (Una fecha por cada jornada).

      fJornadas <- apply(data.frame(vDays, vMonths, vYear, stringsAsFactors=FALSE), 1, formatFechaJornada) 

La función **formatFechaJornada** está definida en el código R que estamos describiendo(*****Webscraping.R*****).

A continuación procedemos a capturar la información de estadísticas de cada jornada:

      resultados <- NULL
      for (i in 1:length(lJornadas)) {
        url <- paste("http://www.marca.com/estadisticas/futbol/primera/" , temporada, "/jornada_", i, "/", sep="")
        
Incluimos un **tryCatch** para que no se corte el proceso en el caso de producirse un enlace incorrecto.

        tryCatch(doc <- read_html(url)
                 , error = function(e)(doc <<- NULL))
                 
Marcamos a **NULL** el valor de la variable **doc** en el caso de no encontrar la página. Esto nos permite no realizar tratamiento si la variable es NULL:

        if (!is.null(doc)) {

Por cada una de las páginas de estadísticas de la jornada, se busca la información de fecha, equipos que participan en la jornada y puntos obtenidos al finalizar la misma. Previamente hemos investigado estas páginas para determinar que etiquetas tenemos que buscar (*****.fecha*****, *****.equipo***** y *****.pts*****) 

          fecha <- html_text(html_nodes(doc, '.fecha'))
          teamsName <<- html_text(html_nodes(doc, '.equipo'))
          teamsPath <<- sapply(teamsName, formatTeamName)
          points <- html_text(html_nodes(doc, '.pts'))
          points <- points[2:length(points)]
      
Vamos guardando la información capturada de cada jornada en la variable resultado.

          resultados <- rbind(resultados,
                              cbind(teamsName, teamsPath, temporada, i, points))
        }
      }

Finalmente como resultado de la función se retornan los valores de las fechas de cada jornada y las estadísticas capturadas. La información de las fechas de cada jornada son importantes ya que nos permitirán identificar que articulos de marca corresponden a que periodo entre jornadas.

      return(list(fJornadas, resultados))
    }

