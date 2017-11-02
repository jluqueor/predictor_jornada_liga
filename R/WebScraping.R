# Manual para hacer scraping
# https://www.analyticsvidhya.com/blog/2017/03/beginners-guide-on-web-scraping-in-r-using-rvest-with-hands-on-knowledge/

# Selector de css
# http://selectorgadget.com/  
  
install.packages("rvest")
library("rvest")
setwd("C:/Users/Carlos/iCloudDrive/Proyectos/PrediccionCampeonLiga")
# --------------------------------------------------------------------------------------------------------------------
# existsTeam:
# ==========
# Comprueba si el equipo sobre el que se comenta en el artículo, es uno de los que participan en la competición
# --------------------------------------------------------------------------------------------------------------------
existsTeam <- function(teamPath) {
  return(length(which(teamsPath==teamPath)) > 0)
}
# --------------------------------------------------------------------------------------------------------------------
# cargaDia_hemerotecaMarca_fmt1:
# =============================
# Recupera datos de marca con el formato de la hemeroteca de fechas posterior a 20160907
# Accediendo a primera-division tiene datos a partir de 18 de 12 de 2015
# --------------------------------------------------------------------------------------------------------------------
cargaDia_hemerotecaMarca_fmt1 <- function(fecha_entrada) {
  fecha <- as.Date(fecha_entrada)
  datos=NULL
  url <- paste("http://www.marca.com/hemeroteca/", format(fecha, format="%Y/%m/%d"), "/futbol/primera-division.html", sep="")
  print(url)
  tryCatch(enlaces_articulos <- read_html(url) %>%
             html_nodes('.mod-title') %>%
             html_children() %>%
             html_attrs()
           , error = function(e){enlaces_articulos <- NULL})
  for (enlace in (enlaces_articulos)) {
    elementosEnlace <- strsplit(as.character(enlace["href"]), split="/")[[1]]
    equipo <- elementosEnlace[5]
    if (existsTeam(equipo)) {
      year <- as.integer(elementosEnlace[6])
      month <- as.integer(elementosEnlace[7])
      day <- as.integer(elementosEnlace[8])
      tryCatch(articulo <<- read_html(as.character(enlace["href"])) %>%
                 html_nodes('.cols-30-70')
               , error = function(e)(articulo <<- NULL))
      if (!is.null(articulo) & length(articulo)>0) {
        componentes <- html_children(articulo[[1]])
  
        for (componente in componentes) {
          if (xml_name(componente)=="p") {
            datos<-rbind(datos, c(equipo, format(fecha, format="%Y"), format(fecha, format="%m"), format(fecha, format="%d"), html_text(componente))) 
          }
        }
      }
    }
  }
  
  return (datos)
}
# --------------------------------------------------------------------------------------------------------------------
# cargaDia_hemerotecaMarca_fmt2:
# =============================
# Recupera datos de marca con el formato de la hemeroteca de fechas anteriores a [,2015-12-17]
# --------------------------------------------------------------------------------------------------------------------
cargaDia_hemerotecaMarca_fmt2 <- function(fecha_entrada) {
  fecha <- as.Date(fecha_entrada)
  datos=NULL
  
  if (fecha < as.Date("2015-12-14")) {
    url <- paste("http://www.marca.com/hemeroteca/", format(fecha, format="%Y/%m/%d"), "/futbol/1adivision.html", sep="")
  } else {
    url <- paste("http://www.marca.com/hemeroteca/", format(fecha, format="%Y/%m/%d"), "/futbol.html", sep="")
  }
  print(url)

  tryCatch(doc <- read_html(url)
           , error = function(e)(doc <<- NULL))
   
  if (!is.null(doc)) { 
      enlaces_articulos <- doc %>%
      html_nodes('.principal') %>%
        html_children()
      enlaces <- enlaces_articulos[html_name(enlaces_articulos)=="h2"] %>%
        html_children() %>%
        html_attrs()
  
    for (enlace in (enlaces)) {
      elementosEnlace <- strsplit(as.character(enlace["href"]), split="/")[[1]]
      equipo <- "HOAX"
      if (length(elementosEnlace)>8 & elementosEnlace[1]=="http:" & elementosEnlace[9]=="equipos") {
        equipo <- elementosEnlace[10]
        year <- as.integer(elementosEnlace[5])
        month <- as.integer(elementosEnlace[6])
        day <- as.integer(elementosEnlace[7])
        vUrl <- as.character(enlaces[[1]]["href"])
      }
      if (length(elementosEnlace)>5 & elementosEnlace[1]=="" & elementosEnlace[6]=="equipos") {
        equipo <- elementosEnlace[7]
        year <- as.integer(elementosEnlace[2])
        month <- as.integer(elementosEnlace[3])
        day <- as.integer(elementosEnlace[4])
        vUrl <- as.character(paste("http://www.marca.com", enlace["href"], sep=""))
      }
      if (existsTeam(equipo)) {
        tryCatch(articulo <<- read_html(vUrl) %>%
                   html_nodes('.cuerpo_articulo')
                 , error = function(e)(articulo <<- NULL))
        if (!is.null(articulo) & length(articulo)>0) {
          componentes <- html_children(articulo[[1]])
          
          for (componente in componentes) {
            if (xml_name(componente)=="p") {
              datos<-rbind(datos, c(equipo, format(fecha, format="%Y"), format(fecha, format="%m"), format(fecha, format="%d"), html_text(componente))) 
            }
          }
        }
      }
    }
      
    enlaces_articulos <- doc %>%
      html_nodes('.secundaria') %>%
      html_children()
    enlaces <- enlaces_articulos[html_name(enlaces_articulos)=="h2" | html_name(enlaces_articulos)=="h3" | html_name(enlaces_articulos)=="h5"] %>%
      html_children() %>%
      html_attrs()
    
    for (enlace in (enlaces)) {
      elementosEnlace <- strsplit(as.character(enlace["href"]), split="/")[[1]]
      equipo <- "HOAX"
      if (length(elementosEnlace)>8 & elementosEnlace[1]=="http:" & elementosEnlace[9]=="equipos") {
        equipo <- elementosEnlace[10]
        year <- as.integer(elementosEnlace[5])
        month <- as.integer(elementosEnlace[6])
        day <- as.integer(elementosEnlace[7])
        vUrl <- as.character(enlaces[[1]]["href"])
      }
      if (length(elementosEnlace)>5 & elementosEnlace[1]=="" & elementosEnlace[6]=="equipos") {
        equipo <- elementosEnlace[7]
        year <- as.integer(elementosEnlace[2])
        month <- as.integer(elementosEnlace[3])
        day <- as.integer(elementosEnlace[4])
        vUrl <- as.character(paste("http://www.marca.com", enlace["href"], sep=""))
      }
      if (existsTeam(equipo)) {
        tryCatch(articulo <<- read_html(vUrl) %>%
                   html_nodes('.cuerpo_articulo')
                 , error = function(e)(articulo <<- NULL))
        if (!is.null(articulo) & length(articulo)>0) {
          componentes <- html_children(articulo[[1]])
          
          for (componente in componentes) {
            if (xml_name(componente)=="p") {
              datos<-rbind(datos, c(equipo, format(fecha, format="%Y"), format(fecha, format="%m"), format(fecha, format="%d"), html_text(componente))) 
            }
          }
        }
      }
    }
  }
  
  return (datos)
}
# --------------------------------------------------------------------------------------------------------------------
# cargaDia_hemerotecaMarca:
# ========================
# Recupera datos de marca con el formato de la hemeroteca de fechas anteriores a [,2015-12-17]
# --------------------------------------------------------------------------------------------------------------------
cargaDia_hemerotecaMarca <- function(fecha_entrada) {
  if (fecha_entrada<as.Date("2015-12-17")) {
    return(cargaDia_hemerotecaMarca_fmt2(fecha_entrada))
  } else {
    return(cargaDia_hemerotecaMarca_fmt1(fecha_entrada))
  }
}
# --------------------------------------------------------------------------------------------------------------------
# formatFechaJornada:
# ==================
# Forma un valor Date con la información de la fecha obtenida del calendario
# --------------------------------------------------------------------------------------------------------------------
formatFechaJornada <- function (datos) {
  day <- datos[1]
  month <- datos[2]
  year <- datos[3]
  f<-"01-01-0001"
  switch(month,
         "Agosto" = {f<-format(as.Date(paste(year, "08", day, sep="-")), format="%Y-%m-%d")},
         "agosto" = {f<-format(as.Date(paste(year, "08", day, sep="-")), format="%Y-%m-%d")},
         "Septiembre" = {f<-format(as.Date(paste(year, "09", day, sep="-")), format="%Y-%m-%d")},
         "septiembre" = {f<-format(as.Date(paste(year, "09", day, sep="-")), format="%Y-%m-%d")},
         "Octubre" = {f<-format(as.Date(paste(year, "10", day, sep="-")), format="%Y-%m-%d")},
         "octubre" = {f<-format(as.Date(paste(year, "10", day, sep="-")), format="%Y-%m-%d")},
         "Noviembre" = {f<-format(as.Date(paste(year, "11", day, sep="-")), format="%Y-%m-%d")},
         "noviembre" = {f<-format(as.Date(paste(year, "11", day, sep="-")), format="%Y-%m-%d")},
         "Diciembre" = {f<-format(as.Date(paste(year, "12", day, sep="-")), format="%Y-%m-%d")},
         "diciembre" = {f<-format(as.Date(paste(year, "12", day, sep="-")), format="%Y-%m-%d")},
         "Enero" = {f<-format(as.Date(paste(as.double(year)+1, "01", day, sep="-")), format="%Y-%m-%d")},
         "enero" = {f<-format(as.Date(paste(as.double(year)+1, "01", day, sep="-")), format="%Y-%m-%d")},
         "Febrero" = {f<-format(as.Date(paste(as.double(year)+1, "02", day, sep="-")), format="%Y-%m-%d")},
         "febrero" = {f<-format(as.Date(paste(as.double(year)+1, "02", day, sep="-")), format="%Y-%m-%d")},
         "Marzo" = {f<-format(as.Date(paste(as.double(year)+1, "03", day, sep="-")), format="%Y-%m-%d")},
         "marzo" = {f<-format(as.Date(paste(as.double(year)+1, "03", day, sep="-")), format="%Y-%m-%d")},
         "Abril" = {f<-format(as.Date(paste(as.double(year)+1, "04", day, sep="-")), format="%Y-%m-%d")},
         "abril" = {f<-format(as.Date(paste(as.double(year)+1, "04", day, sep="-")), format="%Y-%m-%d")},
         "Mayo" = {f<-format(as.Date(paste(as.double(year)+1, "05", day, sep="-")), format="%Y-%m-%d")},
         "mayo" = {f<-format(as.Date(paste(as.double(year)+1, "05", day, sep="-")), format="%Y-%m-%d")},
         "Junio" = {f<-format(as.Date(paste(as.double(year)+1, "06", day, sep="-")), format="%Y-%m-%d")},
         "junio" = {f<-format(as.Date(paste(as.double(year)+1, "06", day, sep="-")), format="%Y-%m-%d")}
  )
  return(f)
}
# --------------------------------------------------------------------------------------------------------------------
# formatTeamName:
# ==============
# Formatea los nombres de los equipos de futbol acordes a formato usado en path del marca
# --------------------------------------------------------------------------------------------------------------------
formatTeamName <- function(equipo) {
  temp <- tolower(equipo)
  temp <- gsub(" ", "-", temp)
  temp <- gsub("Á", "a", temp)
  temp <- gsub("É", "e", temp)
  temp <- gsub("Í", "e", temp)
  temp <- gsub("Ó", "e", temp)
  temp <- gsub("Ú", "e", temp)
  temp <- gsub("á", "a", temp)
  temp <- gsub("é", "e", temp)
  temp <- gsub("í", "e", temp)
  temp <- gsub("ó", "e", temp)
  temp <- gsub("ú", "e", temp)
  temp <- gsub("r.", "real", temp, fixed=TRUE)
  return(temp)
}
# ---------------------------------------------------------------------------------------------------------------------
# getResults:
# ==========
# Busqueda de equipos que participan en una temporada, las fechas de cada jornada  y los resultados obtenidos por cada
# equipo
# ---------------------------------------------------------------------------------------------------------------------
getResults <- function(vYear) {
  temporada <- paste(vYear, substring(as.double(vYear)+1, 3, 4), sep="_")
  url <- paste("http://www.marca.com/estadisticas/futbol/primera/" , temporada, "/jornada_1/", sep="")
  doc <- read_html(url)

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
# ---------------------------------------------------------------------------------------------------------------------
# procesaTemporada:
# ================
# Realiza el tramiento para una temporada completa. Carga información de resultados y busca los articulos del año.
# ---------------------------------------------------------------------------------------------------------------------
procesaTemporada <- function(year) {
  articlesSeason <- NULL
  a<-getResults(year)
  recFecha <- as.Date(a[[1]][1])-7
  dias<-as.Date(a[[1]][length(a[[1]])])-as.Date(a[[1]][1])-7
  for (i in (1:dias)) {
    articlesSeason <- as.data.frame(rbind(articlesSeason, cargaDia_hemerotecaMarca(recFecha)))
    recFecha <- recFecha + 1
  }
  articlesSeason <- unique(articlesSeason[,1:5])
  save(articlesSeason, file=paste("D:/TRAPICHEO/data.frame/articulos_", year, ".Rda", sep=""))
}
procesaTemporada("2016")
procesaTemporada("2015")
procesaTemporada("2014")
procesaTemporada("2013")
procesaTemporada("2012")
procesaTemporada("2011")

