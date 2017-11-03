# Web Scraping páginas de Marca

Proceso de rastreo de las páginas de **Marca** para obtener de su hemeroteca información de artículos publicados e información de estadísticas por jornada.

Hay multitud de sitios web y modos de realizar '***webscraping***'. Para realizar el proceso desde código R, en este proyecto utilizamos el paquete *****rvest***** y nos hemos ayudado de las descripciones que se realizan sobre este paquete en esta página: [beginners guide](https://www.analyticsvidhya.com/blog/2017/03/beginners-guide-on-web-scraping-in-r-using-rvest-with-hands-on-knowledge/).

Para realizar '***webscraping***' se requiere tener unos conocimientos mínimos del lenguaje **HTML** y de como se codifican las páginas web. Normalmente, no queremos la totalidad de información que aparece en una página web y es necesario identificar que partes de la misma queremos sacar. Para el caso de las páginas de **Marca**, nos interesa la información de los diferentes artículos que se incluyen en el diario en cada día de su hemeroteca, concretamente los enlaces a los artículos completos, siendo necesario analizar la estructura de los artículos completos para poder sacar exclusivamente la información del texto de los artículos.

Para ayudar a realizar esta tarea, en la documentación del propio paquete de *****rvest***** aconsejan utilizar un selector de **CSS**, en concreto usar el ***plugin*** [selector gadget](http://selectorgadget.com/) que se incorpora como elemento del navegador **Chrome**.

![Selector CSS](https://github.com/jluqueor/predictor_jornada_liga/blob/master/img/webScrapingSelectorCSS.JPG).

También ayuda explorar el código de la página web, por ejemplo con la funcionalidad **inspeccionar** del navegador **Chrome**:

![Inspeccionar](https://github.com/jluqueor/predictor_jornada_liga/blob/master/img/InspeccionarElementoChrome.JPG)

El código que realiza el webscraping está en el módulo *****WebScraping.R*****. A continuación se describe detalladamente el proceso de webscraping correspondiente a la captura de información de estadísticas de cada jornada. El resto del código se puede descargar del proyecto.

    # ---------------------------------------------------------------------------------------------------------------------
    # getResults:
    # ==========
    # Busqueda de equipos que participan en una temporada, las fechas de cada jornada  y los resultados obtenidos por cada
    # equipo
    # ---------------------------------------------------------------------------------------------------------------------
    getResults <- function(vYear) {
      temporada <- paste(vYear, substring(as.double(vYear)+1, 3, 4), sep="_")
      url <- paste("http://www.marca.com/estadisticas/futbol/primera/" , temporada, "/jornada_1/", sep="")

Se Formatea la ruta **http** correspondiente a la temporada que queremos consultar.

      doc <- read_html(url)

La f
  lJornadas <- html_attrs(html_children(html_children(html_children(html_nodes(doc, '.navegacion-jornadas')))))
  calendario <- NULL
  for (jornada in lJornadas) {
    calendario <- rbind(calendario, jornada["title"])
  }
  charCalen <- strsplit(calendario, split=" ")
  # Cada elemento de charCalen tiene la forma <dia1> "y" <dia2> <mes>.
  # tomamos el valor de <dia2> (3 posición)
  vDays <- unlist(lapply(charCalen, function(x) {x[3]}))
  # tomamos el valor de <mes> (4 posición)
  vMonths <- unlist(lapply(charCalen, function(x) {x[4]}))
  fJornadas <- apply(data.frame(vDays, vMonths, vYear, stringsAsFactors=FALSE), 1, formatFechaJornada) 

  jornadas <- html_text(html_children(html_children(html_children(html_nodes(doc, '.navegacion-jornadas')))))
  
  resultados <- NULL
  for (i in 1:length(jornadas)) {
    url <- paste("http://www.marca.com/estadisticas/futbol/primera/" , temporada, "/jornada_", i, "/", sep="")
    print(url)
    #Reading the HTML code from the website
    tryCatch(doc <- read_html(url)
             , error = function(e)(doc <<- NULL))
    if (!is.null(doc)) {
      fecha <- html_text(html_nodes(doc, '.fecha'))
      teamsName <<- html_text(html_nodes(doc, '.equipo'))
      teamsPath <<- sapply(teamsName, formatTeamName)
      points <- html_text(html_nodes(doc, '.pts'))
      points <- points[2:length(points)]
      
      resultados <- rbind(resultados,
                          cbind(teamsName, teamsPath, temporada, i, points))
    }
  }
  return(list(fJornadas, resultados))
}

'''
x <- 13
'''

    x <- 13
