# --------------------------------------------------------------------------------------
# calProgresion:
# =============
# Calcula como evoluciona cada equipo de una jornada a la siguiente:
# Se basa en la matriz generada y genera nuevas columnas con la evolución entre dos jornadas 
# que también se pasan como parámetros.
# -1 --> Perdió el partido
#  0--> Empató
#  1 --> Ganó
# --------------------------------------------------------------------------------------
calProgresion <- function (origen, destino, nueva) {
  matrizResultados[,nueva] <<- apply(as.data.frame(cbind("estado_ori"=matrizResultados[,origen],
                                                         "estado_des"=matrizResultados[,destino])),
                                     1,
                                     function(x) {
                                       if (x["estado_ori"]==x["estado_des"])
                                       {return (-1)}
                                       else
                                         if (x["estado_des"]==x["estado_ori"]+1)
                                         {return (0)}
                                       else return(1)})
}
# --------------------------------------------------------------------------------------
# hacerTransformacion:
# ===================
# Calcula como evoluciona cada equipo de una jornada a la siguiente:
# Se basa en la matriz generada y genera nuevas columnas con la evolución entre dos jornadas 
# que también se pasan como parámetros.
# -1 --> Perdió el partido
#  0--> Empató
#  1 --> Ganó
# --------------------------------------------------------------------------------------
hacerTransformacion <- function(year) {
  # Leemos el fichero que contiene los datos de los resultados de año recibido como parámetro
  resultados = read.csv(file=paste("resultados_", year, ".csv", sep=""), stringsAsFactors = FALSE, fileEncoding="UTF-8")

  # genera variable para identificar año/mes.
  resultados$jornada <- as.factor(paste(resultados$temporada, "/", sprintf("%02d", resultados$i), sep=""))
  
  # Estructura de matriz para aplanar la información de las diferentes jornadas por equipo.
  matrizResultados <<- resultados[resultados$i==1,c("teamsName","teamsPath","temporada")]

  # pegamos los puntos obtenidos por cada equipo en cada jornada
  for (jornada in 1:max(resultados$i)) {
    matrizResultados <<- merge(x=matrizResultados, 
                              unique(resultados[resultados$i==jornada, c("teamsName","teamsPath","temporada","points")]), 
                              all=TRUE, 
                              by=c("teamsName","teamsPath","temporada"), 
                              suffixes=c("",paste("_", jornada,sep="")))
  }
  
  # corregimos el nombre de la primera jornada para la que no tuvo efecto el parámetro suffixes (no existía la columna)sigue el mismo patrón de nombres para las dos primera columnas a?adidas a matrizEstados
  colnames(matrizResultados)[which(colnames(matrizResultados)=="points")] <<-"points_1"
  
  # Por cada dos jornadas consecutivas llamamos a la función calProgresion para calcular como evolucionó cada 
  # equipo en ese periodo (añade una nueva columna en matrizResultados con la evolución)
  for (jornada in 1:(max(resultados$i)-1)) {
    calProgresion(paste("points_", jornada, sep=""),
                  paste("points_", jornada+1, sep=""),
                  paste("E", jornada, "_to_", jornada+1, sep=""))
  }
  
  # Sacamos en una pequeña tabla la información de las fechas de cada jornada, para poder establecer los tramos de articulos 
  # correspondientes a cada jornada
  calendario <- unique(resultados[,c("temporada","i","fecha")])
  calendario[,"iniJornada"] <- as.Date(calendario$fecha)-1
  
  # Pasamos a buscar los articulos correspondientes a cada jornada.
  # Leemos el fichero que contiene los articulos publicados para cada equipo y fecha
  recortes = read.csv(file=paste("articulos_", year, ".csv", sep=""), stringsAsFactors = FALSE, fileEncoding="UTF-8")
  
  # Ponemos nombres a las columnas
  colnames(recortes) <- c("teamsPath", "year", "month", "day", "articulo")
  # De los datos, sacamos la fecha de publicación y la convertimos a Date
  recortes$fecha <- as.Date(paste(recortes$year,recortes$month,recortes$day, sep="-"))

  # normaliza cambio en nombre de equipos (separadores usados '-' y '_' en distintos periodos)
  recortes$teamsPath <- gsub("-", "_", recortes$teamsPath)
  
  # Concatenamos los diferentes articulos escritos sobre un equipo y fecha en un único string
  articulos <- aggregate(articulo ~ teamsPath + fecha, recortes, paste, collapse=" ")
  
  # Identificamos la jornada a la que corresponde cada artículo.
  articulos[,"jornada"] <- 1
  for (jornada in 2:dim(calendario)[1]) {
    articulos[(articulos$fecha>=calendario$iniJornada[jornada-1]) & (articulos$fecha<calendario$iniJornada[jornada]),"jornada"] <- jornada
  }
  
  # Concatenamos ahora los diferentes artículos escritos sobre cada equipo previos a la jornada
  articulosJornada <- aggregate(articulo ~ teamsPath + jornada, articulos, paste, collapse=" ")
  
  # Generamos un tablón con la información:
  # equipo: Identificador del equipo.
  # articulos: string que concatena la lista completa de artículos escritos sobre el equipo en los días previos a la jornada.
  # temporada: Temporada.
  # puntos: Puntos de los que parte el equipo antes de la jornada.
  # Evolución: Objetivo de la jornada. Evolución resultado del equipo al finalizar la jornada.
  # jornada: Número de la jornada anterior.jornada anterior
  tablon <- NULL
  for (i in 1:(dim(calendario)[1]-1)) {
    temp <- merge(x=articulosJornada[articulosJornada$jornada==i,c("teamsPath", "articulo")],
                  cbind(matrizResultados[,c("teamsPath","temporada", paste("points_", i, sep=""),paste("E", i, "_to_", i+1, sep=""))], "jornada"=i),
                  all=TRUE, by=c("teamsPath"))
    colnames(temp) <- c("teamsPath", "articulos",  "temporada", "puntos",  "Evolucion", "jornada")
    tablon <- rbind(tablon, temp[,c("teamsPath", "temporada", "jornada", "puntos",  "Evolucion", "articulos")])
  }
  # Ya tenemos la información preparada para hacer text-mining. Descargamos los datos a disco.

  write.csv(tablon,  file=paste("tablon_", year, ".csv", sep=""), row.names=FALSE, quote=TRUE, fileEncoding="UTF-8")
} 

setwd("C:/Users/Carlos/iCloudDrive/Proyectos/PrediccionCampeonLiga/data.frame")
hacerTransformacion("2017")
hacerTransformacion("2016")
hacerTransformacion("2015")
hacerTransformacion("2014")
hacerTransformacion("2013")
hacerTransformacion("2012")



