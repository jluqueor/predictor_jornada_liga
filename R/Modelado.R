library(DBI)         
library(NLP)         
library(tm)          
library(SnowballC)   
library(sqldf)
library(xgboost)
library(readr)
library(Matrix)

# --------------------------------------------------------------------------------------
# creaCarpeta:
# ===========
# Crea carpeta y estructura de archivo de resumen para iniciar un modelo
# --------------------------------------------------------------------------------------
creaCarpeta <- function(path) {
  temp <- getwd()
  setwd(path)
  xTime <- Sys.time()
  carpeta <- paste("Modelo_", substr(xTime,1,10), "-", substr(xTime,12,13), ".", substr(xTime,15,16), ".", substr(xTime,18,19), sep="")
  system(paste("cmd.exe /c mkdir ", carpeta, sep=""))
  setwd(carpeta)
  
  resumen.colnames <- c("fecha",
                        "Train_precision", "Train_recall", "Train_f1_score", "Train_acierto",
                        "Dev_precision", "Dev_recall", "Dev_f1_score", "Dev_acierto")
  resumen <- data.frame(t(c(1, 2, 3, 4, 5, 6, 7, 8, 9)))
  names(resumen) <- resumen.colnames
  write.table(resumen[0,],
              file=paste("resumen.txt", sep=""),
              append=TRUE, col.names=TRUE, row.names=FALSE)

  setwd(temp) 
  
  return(carpeta)
}
# --------------------------------------------------------------------------------------
# entrenaModelo:
# =============
# Lanza un entrenamiento
# --------------------------------------------------------------------------------------
entrenaModelo <- function(train, Y, xEta=0.3, xLambda=1.0, xSubsample=1.0, xAlpha=0, xNthread=10, xLambdaBias=0, xNround=100, xModel=NULL, xSave="xgboost.model", saveModel=TRUE) {
  param <- list( # https://github.com/dmlc/xgboost/blob/master/doc/parameter.md
    max.depth = 6
    , objective = "multi:softmax"
    , num_class = 3
    , booster="gbtree"
    , eta = xEta                 
    , min_child_weight = 1
    , subsample = xSubsample # con valores menores puede hacer que no se produzca overfitting
    , colsample_bytree=1
    , eval_metric = "mlogloss"
    , lambda=xLambda             # L2 regularization
    , lambda_bias=xLambdaBias    # L2 regularization
    , alpha=xAlpha               # L1 regularization
    , base_score=0.5
  )
  
  if (saveModel) {fichero <- xSave}
  else {fichero <- "temp.model"}
  
  set.seed(1)
  bst <- xgboost(data = train, label = Y, params =param
                 , nround = xNround
                 , nthread = xNthread
                 , silent=0
                 , verbose=1
                 , print_every_n = 50L
                 , xgb_model = xModel
                 , save_name = fichero
  )
  
  return(bst)
}
# --------------------------------------------------------------------------------------
# procesaModelo:
# =============
# Lanza un proceso de entrenamiento tantas veces como iteraciones se hayan indicado
# --------------------------------------------------------------------------------------
procesaModelo <- function(X, target, strWords, cmm, condTrain, condDev, parametros, modelo=NULL, iteraciones=1, ... ) {
  xTime <- Sys.time()
  Y   <- c(0, target[condTrain])
  cmmData <-  c(paste(strWords, collapse=" "), cmm[condTrain])
  dtmData <- DocumentTermMatrix(Corpus(VectorSource(cmmData)), control=list(dictionary=strWords))
  sparseTrain <- sparseMatrix(i=dtmData$i, j=dtmData$j, x=dtmData$v, dimnames=dimnames(dtmData))
  c <- c(1:(sparseTrain@Dim[2]))
  cMax <- sapply(c, function(j) {
    max(sparseTrain@x[(sparseTrain@p[j]+1):sparseTrain@p[j+1]])})
  sparseTrain <- sparseTrain %*% Matrix::Diagonal(x = 1 / cMax)
  write(cMax, file=paste(substr(xTime,1,10), "-", substr(xTime,12,13), ".", substr(xTime,15,16), ".", substr(xTime,18,19),"_cMax_", parametros, ".RData", sep=""))
  
  YDev <- c(0, target[condDev])
  
  cmmData <-  c(paste(strWords, collapse=" "), cmm[condDev])
  dtmData <- DocumentTermMatrix(Corpus(VectorSource(cmmData)), control=list(dictionary=strWords))
  sparseDev <- sparseMatrix(i=dtmData$i, j=dtmData$j, x=dtmData$v, dimnames=dimnames(dtmData))
  sparseDev <- sparseDev %*% Matrix::Diagonal(x = 1 / cMax)
  
  Y_Train <- Y
  Y_Train[Y_Train==1] <- 2
  Y_Train[Y_Train==0] <- 1
  Y_Train[Y_Train==-1] <- 0
  
  Y_Dev <- YDev
  Y_Dev[Y_Dev==1] <- 2
  Y_Dev[Y_Dev==0] <- 1
  Y_Dev[Y_Dev==-1] <- 0
  
  for (i in 1:iteraciones) {
    xTime <- Sys.time()
    bst <- entrenaModelo(sparseTrain, Y_Train, xModel=modelo,
                         xSave=paste(substr(xTime,1,10), "-", substr(xTime,12,13), ".", substr(xTime,15,16), ".", substr(xTime,18,19), "_modelo_", parametros, ".model", sep=""),
                         ...) 
    modelo <- bst
    res <- c(prediccion(bst, sparseTrain, Y_Train), prediccion(bst, sparseDev, Y_Dev))
    names(res) <- c("Train_precision", "Train_recall", "Train_f1_score", "Train_acierto",
                    "Dev_precision", "Dev_recall", "Dev_f1_score", "Dev_acierto")
    
    resumen <- c(fecha=paste(substr(xTime,1,10), "-", substr(xTime,12,19), sep=""), res)
    write.table(data.frame(t(resumen)),
                file=paste("resumen.txt", sep=""),
                append=TRUE, col.names=FALSE, row.names=FALSE)
  }
  
  return(list(resumen=resumen, bst=bst))
}
# --------------------------------------------------------------------------------------
# prediccion:
# ==========
# Lanza una predicción y verifica que tal es el resultado del mismo
# --------------------------------------------------------------------------------------
prediccion <- function(bst, sparseData, Y) {
  
  predice <- predict(bst, sparseData)
  precision <- length(predice[(predice==0 & Y==0) | (predice==2 & Y==2)])/length(Y[predice==0 | predice==2])
  recall <- length(predice[(predice==0 & Y==0) | (predice==2 & Y==2)])/length(Y[(Y==0 & predice==0) | (Y==2 & predice==2) | (Y==0 & predice==1) | (Y==2 & predice==1)])
  f1_score <- 2*(precision*recall)/(precision+recall)
  acierto <- length(predice[predice==Y])/length(Y)*100
  return(c(precision, recall, f1_score, acierto))
}
# --------------------------------------------------------------------------------------
# muestraResultados:
# =================
# Lee la informacion de resumen de un entrenamiento y presenta la información en gráficas
# --------------------------------------------------------------------------------------
muestraResultados <- function(path, carpeta) {
  resumen <- read_delim(paste(path, carpeta, "/resumen.txt", sep=""), " ", escape_double = FALSE, trim_ws = TRUE)
  
  iter <- trunc(dim(resumen)[1]*1.2)
  
  # f1_score
  plot(x=c(1,iter), y=c(0,1), type="n", xlab="iteraciones", ylab="score")
  lines(resumen$Train_f1_score, type="l", col="red")
  lines(resumen$Dev_f1_score, type="l", col="blue")
  legend("topright", legend=c("Train", "Dev"), fill = c("red", "blue"), border= c("red", "blue"))
  title("F1 score")
  # precisión
  plot(x=c(1,iter), y=c(0,1), type="n", xlab="iteraciones", ylab="precisión")
  lines(resumen$Train_precision, type="l", col="red")
  lines(resumen$Dev_precision, type="l", col="blue")
  legend("topright", legend=c("Train", "Dev"), fill = c("red", "blue"), border= c("red", "blue"))
  title("Precisión")
  # recall
  plot(x=c(1,iter), y=c(0,1), type="n", xlab="iteraciones", ylab="recall")
  lines(resumen$Train_recall, type="l", col="red")
  lines(resumen$Dev_recall, type="l", col="blue")
  legend("topright", legend=c("Train", "Dev"), fill = c("red", "blue"), border= c("red", "blue"))
  title("Recall")
  # acierto
  plot(x=c(1,iter), y=c(1,100), type="n", xlab="iteraciones", ylab="% acierto")
  lines(resumen$Train_acierto, type="l", col="red")
  lines(resumen$Dev_acierto, type="l", col="blue")
  legend("topright", legend=c("Train", "Dev"), fill = c("red", "blue"), border= c("red", "blue"))
  title("Acierto entrenamiento")
  
  return (resumen) 
}

set.seed(1)

path <- "C:/Users/Carlos/iCloudDrive/Proyectos/PrediccionCampeonLiga/"
setwd(paste(path, "data.frame", sep=""))
datos<-read.csv("datos_procesados.csv", stringsAsFactors = FALSE)
load("environment_datos_procesados.Rda")

xRandom <- sample(nrow(datos), nrow(datos))
xCarpeta <- creaCarpeta("C:/Users/Carlos/iCloudDrive/Proyectos/PrediccionCampeonLiga")
setwd(paste(path, xCarpeta, sep=""))

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

resumen <- muestraResultados(path, xCarpeta)

xCarpeta <- creaCarpeta("C:/Users/Carlos/iCloudDrive/Proyectos/PrediccionCampeonLiga")
setwd(paste(path, xCarpeta, sep=""))

a <- procesaModelo("X"=datos[xRandom,],
                   "target"=datos$Evolucion[xRandom],
                   "strWords"=strPalabras,
                   "cmm"=cmm_palabras,
                   "condTrain"=(1:(round(nrow(datos)*0.8))),
                   "condDev"=(((round(nrow(datos)*0.8))+1):(round(nrow(datos)*0.9))),
                   parametros="random_palabras_10Rounds_1jornada",
                   iteraciones=10,
                   xNthread=10,
                   xNround=10)

resumen <- muestraResultados(path, xCarpeta)

xCarpeta <- creaCarpeta("C:/Users/Carlos/iCloudDrive/Proyectos/PrediccionCampeonLiga")
setwd(paste(path, xCarpeta, sep=""))

for (i in seq(from=0, to=1, by=0.1)) {
  a <- procesaModelo("X"=datos[xRandom,],
                     "target"=datos$Evolucion[xRandom],
                     "strWords"=strPalabras,
                     "cmm"=cmm_palabras,
                     "condTrain"=(1:(round(nrow(datos)*0.8))),
                     "condDev"=(((round(nrow(datos)*0.8))+1):(round(nrow(datos)*0.9))),
                     parametros="random_palabras_10Rounds_6meses",
                     iteraciones=1,
                     xLambda=i,xNround=100)
}
for (i in seq(from=2, to=10, by=1)) {
  a <- procesaModelo("X"=datos[xRandom,],
                     "target"=datos$Evolucion[xRandom],
                     "strWords"=strPalabras,
                     "cmm"=cmm_palabras,
                     "condTrain"=(1:(round(nrow(datos)*0.8))),
                     "condDev"=(((round(nrow(datos)*0.8))+1):(round(nrow(datos)*0.9))),
                     parametros="random_palabras_10Rounds_6meses",
                     iteraciones=1,
                     xLambda=i,xNround=100)
}
for (i in seq(from=20, to=100, by=10)) {
  a <- procesaModelo("X"=datos[xRandom,],
                     "target"=datos$Evolucion[xRandom],
                     "strWords"=strPalabras,
                     "cmm"=cmm_palabras,
                     "condTrain"=(1:(round(nrow(datos)*0.8))),
                     "condDev"=(((round(nrow(datos)*0.8))+1):(round(nrow(datos)*0.9))),
                     parametros="random_palabras_10Rounds_6meses",
                     iteraciones=1,
                     xLambda=i,xNround=100)
}
for (i in seq(from=200, to=1000, by=100)) {
  a <- procesaModelo("X"=datos[xRandom,],
                     "target"=datos$Evolucion[xRandom],
                     "strWords"=strPalabras,
                     "cmm"=cmm_palabras,
                     "condTrain"=(1:(round(nrow(datos)*0.8))),
                     "condDev"=(((round(nrow(datos)*0.8))+1):(round(nrow(datos)*0.9))),
                     parametros="random_palabras_10Rounds_6meses",
                     iteraciones=1,
                     xLambda=i,xNround=100)
}
resumen <- muestraResultados(path, xCarpeta)

xCarpeta <- creaCarpeta("C:/Users/Carlos/iCloudDrive/Proyectos/PrediccionCampeonLiga")
setwd(paste(path, xCarpeta, sep=""))

for (i in seq(from=900, to=1200, by=100)) {
  a <- procesaModelo("X"=datos[xRandom,],
                     "target"=datos$Evolucion[xRandom],
                     "strWords"=strPalabras,
                     "cmm"=cmm_palabras,
                     "condTrain"=(1:(round(nrow(datos)*0.8))),
                     "condDev"=(((round(nrow(datos)*0.8))+1):(round(nrow(datos)*0.9))),
                     parametros="random_palabras_10Rounds_6meses",
                     iteraciones=1,
                     xLambda=i,xNround=200)
}
resumen <- muestraResultados(path, xCarpeta)






xCarpeta <- creaCarpeta(Sys.time())
a <- procesaModelo("X"=CClean[xRandom,],
                   "strWords"=strLemas,
                   "cmm"=cmm_lemas,
                   "condTrain"=(1:(round(nrow(CClean)*0.8))),
                   "condDev"=(((round(nrow(CClean)*0.8))+1):(round(nrow(CClean)*0.9))),
                   parametros="random_lemas_100Rounds_6meses",
                   iteraciones=20,
                   xNthread=10, xLambda=200,xNround=500)


resumen <- muestraResultados(xCarpeta)








path <- "C:/Users/Carlos/iCloudDrive/Proyectos/PrediccionCampeonLiga"


temp <- getwd()
setwd(path)
xTime <- Sys.time()
carpeta <- paste("Modelo_", substr(xTime,1,10), "-", substr(xTime,12,13), ".", substr(xTime,15,16), ".", substr(xTime,18,19), sep="")
system(paste("cmd.exe /c mkdir ", carpeta, sep=""))
setwd(paste(substr(xTime,1,10), "-", substr(xTime,12,13), ".", substr(xTime,15,16), ".", substr(xTime,18,19), "_Modelado", sep=""))

resumen.colnames <- c("fecha",
                      "Train_precision", "Train_recall", "Train_f1_score", "Train_acierto",
                      "Dev_precision", "Dev_recall", "Dev_f1_score", "Dev_acierto")
resumen <- data.frame(t(c(1, 2, 3, 4, 5, 6, 7, 8, 9)))
names(resumen) <- resumen.colnames
write.table(resumen[0,],
            file=paste("resumen.txt", sep=""),
            append=TRUE, col.names=TRUE, row.names=FALSE)

setwd(temp) 
