setwd("/workspace/x869183/PoC-Tallyman")

fechasis <- Sys.Date()
# Orden de estados (mejor a peor):
# -------------------------------
# "A" -> "I"-> "M" -> "P" -> "T" - > "F", o bien aumenta el importe impagado ("impirr")
# "A": Estado inventado para indicar contrato en estado normal.
# "I": Impago
# "M": Mora
# "P": Pre-contencioso
# "T": Contencioso
# "F": Fallido
tablaEstados <- c("A", "I", "M", "P", "T", "F")
labelEstados <- c("Normal", "Irregular", "Mora", "Pre-contencioso", "Contencioso", "Fallido")

estados<-read.csv("comentarios_estados_mes_2017-08-08v1.csv")
# genera variable para identificar año/mes.
estados$year_mes <- as.factor(paste(estados$year, "-", sprintf("%02d", estados$month), sep=""))
# Inicializa matriz con la lista de contratos del primer mes
iFecDesde <- which(levels(estados$year_mes)=="2016-04")
level <- estados$year_mes==levels(estados$year_mes)[iFecDesde]
matrizEstados <- as.data.frame(unique(cbind(persona=as.character(estados$persona[level]), tipopers=as.character(estados$tipopers[level]), codpers=as.character(estados$codpers[level]))))

# cargaLevel: Función que añade en vector de contratos la información de estado correspondiente a un mes
# ---------- Añade a matrizEstados la nueva columna y los contratos que aparecen nuevos.
cargaLevel <- function(nivel, colname) {
 level <- estados$year_mes==levels(estados$year_mes)[nivel]
 matrizEstados <<- merge(x=matrizEstados, unique(estados[level, c("persona", "tienehipoteca", "ncontratos", "estado", "dias", "impago", "comentario", "long_comentario")]), all=TRUE, by="persona", suffixes=c("",paste("_", colname,sep="")))
 names(matrizEstados)[names(matrizEstados)=="estado"] <<- paste(colname, "_N", sep="")
 matrizEstados[,colname] <<- sapply(matrizEstados[,paste(colname, "_N", sep="")], function(x) {return(tablaEstados[(x+1)])})
}

iFecHasta <- which(levels(estados$year_mes)=="2017-05")


#matrizEstados$persona <- as.character(matrizEstados$persona)
# Bucle para cargar en matrizEstados los datos de todos los meses
for (i in iFecDesde:iFecHasta) {
 cargaLevel(i, paste("F", levels(estados$year_mes)[i], sep=""))
}

# sigue el mismo patrón de nombres para las dos primera columnas añadidas a matrizEstados
colnames(matrizEstados)[which(colnames(matrizEstados)=="tienehipoteca")] <-paste("tienehipoteca_F", substr(levels(estados$year_mes)[iFecDesde], 1, 7), sep="")
colnames(matrizEstados)[colnames(matrizEstados)=="ncontratos"] <-paste("ncontratos_F", substr(levels(estados$year_mes)[iFecDesde], 1, 7), sep="")
colnames(matrizEstados)[colnames(matrizEstados)=="dias"] <-paste("dias_F", substr(levels(estados$year_mes)[iFecDesde], 1, 7), sep="")
colnames(matrizEstados)[colnames(matrizEstados)=="impago"] <-paste("impago_F", substr(levels(estados$year_mes)[iFecDesde], 1, 7), sep="")
colnames(matrizEstados)[colnames(matrizEstados)=="comentario"] <-paste("comentario_F", substr(levels(estados$year_mes)[iFecDesde], 1, 7), sep="")
colnames(matrizEstados)[colnames(matrizEstados)=="long_comentario"] <-paste("long_comentario_F", substr(levels(estados$year_mes)[iFecDesde], 1, 7), sep="")

# Establece la evolución de cada registro sobre la información de dos meses diferentes
calProgresion <- function (origen, destino, nueva) {
 matrizEstados[,nueva] <<- apply(as.data.frame(cbind("estado_ori"=matrizEstados[,paste(origen, "_N", sep="")], "impago_ori"=matrizEstados[,paste("impago_", origen, sep="")], "dias_ori"=matrizEstados[,paste("dias_", origen, sep="")],
 "estado_des"=matrizEstados[,paste(destino, "_N", sep="")], "impago_des"=matrizEstados[,paste("impago_", destino, sep="")], "dias_des"=matrizEstados[,paste("dias_", destino, sep="")])),
 1,
 function(x) {
 if (x["estado_ori"]<x["estado_des"] |
 (x["estado_ori"]==x["estado_des"] &
 ((x["impago_ori"]*0.9)<x["impago_des"] | x["dias_ori"] > x["dias_des"])))
 {return (1)}
 else
 if (x["estado_ori"]==x["estado_des"] &
 ((x["impago_ori"]*1.1)<x["impago_des"] | (x["dias_ori"]+28) > x["dias_des"]))
 {return (0)}
 else return(-1)})
}
# Bucle para establecer la evolución a un mes
for (i in iFecDesde:(iFecHasta-1)) {
 calProgresion(paste("F", levels(estados$year_mes)[i], sep=""),
 paste("F", levels(estados$year_mes)[(i+1)], sep=""),
 paste("E", levels(estados$year_mes)[(i)], "_to_", levels(estados$year_mes)[(i+1)], "_N", sep=""))
}
tablon <- NULL
for (i in iFecDesde:(iFecHasta-1)) {
 desde<-levels(estados$year_mes)[i]
 hasta<-levels(estados$year_mes)[i+1]
 tablon <- rbind(tablon, cbind(matrizEstados[,c("persona","tipopers","codpers")],
 "year"=substr(desde,1,4),
 "month"=substr(desde,6,7),
 "contratos"=matrizEstados[,paste("ncontratos_F",desde,sep="")],
 "dias"=matrizEstados[,paste("dias_F",desde,sep="")],
 "impago"=matrizEstados[,paste("impago_F",desde,sep="")],
 "estado_N"=matrizEstados[,paste("F",desde,"_N",sep="")],
 "long_comentario"=matrizEstados[,paste("long_comentario_F",desde,sep="")],
 "target_N"=matrizEstados[,paste("F",hasta,"_N",sep="")],
 "target"=matrizEstados[,paste("E",desde,"_to_",hasta,"_N",sep="")],
 "estado_A"=matrizEstados[,paste("F",desde,sep="")],
 "target_A"=matrizEstados[,paste("F",hasta,sep="")],
 "comentario"=matrizEstados[,paste("comentario_F",desde,sep="")]))
}
write.csv(tablon,file=paste("tablon_1mes_", fechasis, "v1.csv", sep=""), row.names=FALSE, quote=TRUE, fileEncoding="UTF-8")

# Bucle para establecer la evolución a tres meses
for (i in iFecDesde:(iFecHasta-3)) {
 calProgresion(paste("F", substr(levels(estados$year_mes)[i], 1, 7), sep=""),
 paste("F", substr(levels(estados$year_mes)[(i+3)], 1, 7), sep=""),
 paste("E", substr(levels(estados$year_mes)[(i)], 1, 7), "_to_", substr(levels(estados$year_mes)[(i+3)], 1, 7), "_N", sep=""))
}
tablon <- NULL
for (i in iFecDesde:(iFecHasta-3)) {
 desde<-levels(estados$year_mes)[i]
 hasta<-levels(estados$year_mes)[i+3]
 tablon <- rbind(tablon, cbind(matrizEstados[,c("persona","tipopers","codpers")],
 "year"=substr(desde,1,4),
 "month"=substr(desde,6,7),
 "contratos"=matrizEstados[,paste("ncontratos_F",desde,sep="")],
 "dias"=matrizEstados[,paste("dias_F",desde,sep="")],
 "impago"=matrizEstados[,paste("impago_F",desde,sep="")],
 "estado_N"=matrizEstados[,paste("F",desde,"_N",sep="")],
 "long_comentario"=matrizEstados[,paste("long_comentario_F",desde,sep="")],
 "target_N"=matrizEstados[,paste("F",hasta,"_N",sep="")],
 "target"=matrizEstados[,paste("E",desde,"_to_",hasta,"_N",sep="")],
 "estado_A"=matrizEstados[,paste("F",desde,sep="")],
 "target_A"=matrizEstados[,paste("F",hasta,sep="")],
 "comentario"=matrizEstados[,paste("comentario_F",desde,sep="")]))
}
write.csv(tablon,file=paste("tablon_3mes_", fechasis, "v1.csv", sep=""), row.names=FALSE, quote=TRUE, fileEncoding="UTF-8")
# Bucle para establecer la evolución a seis meses
for (i in iFecDesde:(iFecHasta-6)) {
 calProgresion(paste("F", substr(levels(estados$year_mes)[i], 1, 7), sep=""),
 paste("F", substr(levels(estados$year_mes)[(i+6)], 1, 7), sep=""),
 paste("E", substr(levels(estados$year_mes)[(i)], 1, 7), "_to_", substr(levels(estados$year_mes)[(i+6)], 1, 7), "_N", sep=""))
}
tablon <- NULL
for (i in iFecDesde:(iFecHasta-6)) {
 desde<-levels(estados$year_mes)[i]
 hasta<-levels(estados$year_mes)[i+6]
 tablon <- rbind(tablon, cbind(matrizEstados[,c("persona","tipopers","codpers")],
 "year"=substr(desde,1,4),
 "month"=substr(desde,6,7),
 "contratos"=matrizEstados[,paste("ncontratos_F",desde,sep="")],
 "dias"=matrizEstados[,paste("dias_F",desde,sep="")],
 "impago"=matrizEstados[,paste("impago_F",desde,sep="")],
 "estado_N"=matrizEstados[,paste("F",desde,"_N",sep="")],
 "long_comentario"=matrizEstados[,paste("long_comentario_F",desde,sep="")],
 "target_N"=matrizEstados[,paste("F",hasta,"_N",sep="")],
 "target"=matrizEstados[,paste("E",desde,"_to_",hasta,"_N",sep="")],
 "estado_A"=matrizEstados[,paste("F",desde,sep="")],
 "target_A"=matrizEstados[,paste("F",hasta,sep="")],
 "comentario"=matrizEstados[,paste("comentario_F",desde,sep="")]))
}
write.csv(tablon,file=paste("tablon_6mes_", fechasis, "v1.csv", sep=""), row.names=FALSE, quote=TRUE, fileEncoding="UTF-8")
