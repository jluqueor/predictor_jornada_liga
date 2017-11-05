library(DBI)         
library(NLP)         
library(tm)          
library(SnowballC)   
library(sqldf)
library(wordcloud)
library(RColorBrewer)

# --------------------------------------------------------------------------------------
# cleanText:
# =========
# Limpia un texto, normalizando el texto, eliminando caracteres no útiles y quitando acentos
# --------------------------------------------------------------------------------------
cleanText<-function(texto, stopwords_sp){
  
  strDesc <- tolower(texto)             # pasar a minúsculas
  strDesc <- gsub("[[:cntrl:]]", " ", strDesc) # elimina saltos de línea y tabulaciones
  
  # Eliminamos acentos:
  strDesc <- gsub("Á", "a", strDesc)  
  strDesc <- gsub("É", "e", strDesc)
  strDesc <- gsub("Í", "i", strDesc)
  strDesc <- gsub("Ó", "o", strDesc)
  strDesc <- gsub("Ú", "u", strDesc)
  strDesc <- gsub("á", "a", strDesc)
  strDesc <- gsub("é", "e", strDesc)
  strDesc <- gsub("í", "i", strDesc)
  strDesc <- gsub("ó", "o", strDesc)
  strDesc <- gsub("ú", "u", strDesc)
  
  strDesc <- gsub("[^a-zA-Z]+", " ",strDesc)
  strDesc<-removePunctuation(strDesc)  # elimina símbolos
  strDesc<-removeNumbers(strDesc)      # elimina números
  strDesc<-stripWhitespace(strDesc)    # elimina espacios blancos extras
  strDesc <- removeWords(strDesc, as.character(t(stopwords_sp))) # Elimina palabras stopwords sin acentos
  strDesc <- gsub("\\s+", " ", trimws(strDesc))           #elimina los espacios sobrantes
  
  return(strDesc)
}
# --------------------------------------------------------------------------------------
# lematizar:
# =========
# Busca lemas de las palabras
# --------------------------------------------------------------------------------------
lematizar<-function(texto){
  palabras<-unlist(strsplit(texto,split=" "))       #separa cada palabra, vector de palabras character
  lemas<-wordStem(palabras, language = "spanish") #extrae la raíz de cada palabra
  paste(lemas[lemas!=""], collapse=" ")
}

pintaWordClouds <- function(corpus) {
  tdm <- TermDocumentMatrix(corpus, control=list(removePunctuation=TRUE, bounds=list(global=c(10, Inf))))
  m <- as.matrix(tdm)
  v <- sort(rowSums(m), decreasing=TRUE)
  d<- data.frame(words=names(v), freq=v)
  head(d, 10)
  
  set.seed(1234)
  
  wordcloud(words = d$word, freq = d$freq, min.freq = 1,
            max.words=200, random.order=FALSE, rot.per=0.35, 
            colors=brewer.pal(8, "Dark2"))
  
  tdm <- TermDocumentMatrix(corpus, control=list(removePunctuation=TRUE, bounds=list(global=c(10, 300))))
  m <- as.matrix(tdm)
  v <- sort(rowSums(m), decreasing=TRUE)
  d<- data.frame(words=names(v), freq=v)
  head(d, 10)
  
  set.seed(1234)
  
  wordcloud(words = d$word, freq = d$freq, min.freq = 1,
            max.words=200, random.order=FALSE, rot.per=0.35, 
            colors=brewer.pal(8, "BrBG"))

  tdm <- TermDocumentMatrix(corpus, control=list(removePunctuation=TRUE, bounds=list(global=c(10, 100))))
  m <- as.matrix(tdm)
  v <- sort(rowSums(m), decreasing=TRUE)
  d<- data.frame(words=names(v), freq=v)
  head(d, 10)
  
  set.seed(1234)
  
  wordcloud(words = d$word, freq = d$freq, min.freq = 1,
            max.words=200, random.order=FALSE, rot.per=0.35, 
            colors=brewer.pal(8, "PRGn"))
  
}

setwd("C:/Users/Carlos/iCloudDrive/Proyectos/PrediccionCampeonLiga/data.frame")

datos<-read.csv("tablon_2012.csv", stringsAsFactors = FALSE, fileEncoding="UTF-8")
datos<-rbind(datos, read.csv("tablon_2013.csv", stringsAsFactors = FALSE, fileEncoding="UTF-8"))
datos<-rbind(datos, read.csv("tablon_2014.csv", stringsAsFactors = FALSE, fileEncoding="UTF-8"))
datos<-rbind(datos, read.csv("tablon_2015.csv", stringsAsFactors = FALSE, fileEncoding="UTF-8"))
datos<-rbind(datos, read.csv("tablon_2016.csv", stringsAsFactors = FALSE, fileEncoding="UTF-8"))

datos <- datos[!is.na(datos$articulos),]
datos <- datos[trimws(datos$articulos)!="",]

stopwords_sp <- read.table("stopwords_sp_noAcentos.txt", col.names=c("palabra"), encoding="UTF-8")
datos$clean <- cleanText(datos$articulos, stopwords_sp)

datos <- datos[datos$clean!="",]

cmm_palabras<-datos$clean
arg_palabras <- c(as.list(cmm_palabras), sep=" ")

cmm_lemas<-apply(as.data.frame(datos$clean),1,lematizar)
arg_lemas <- c(as.list(cmm_lemas), sep=" ")
temporal1 <- as.data.frame(cbind(lema=unlist(strsplit(do.call(paste, arg_lemas),split=" ")), palabra=unlist(strsplit(do.call(paste, arg_palabras),split=" "))))
asociacion<-sqldf("select lema, coalesce(palabra,0) as palabras
                  from temporal1 group by lema order by lema")
rm(temporal1)
asociacion$lema <- as.character(asociacion$lema)

corpus <- Corpus(VectorSource(cmm_lemas))
dtm <- DocumentTermMatrix(corpus, control=list(removePunctuation=TRUE, bounds=list(global=c(10, Inf))))

strLemas <- dtm$dimnames$Terms
corpusLemas <- data.frame("lema"=dtm$dimnames$Terms)
corpusLemas$lema <- as.character(corpusLemas$lema)
corpusLemas <- merge(x=corpusLemas, y=asociacion, by="lema", all.x = TRUE, all.y=FALSE)

rm(corpus, dtm)
corpus <- Corpus(VectorSource(cmm_palabras))
dtm <- DocumentTermMatrix(corpus, control=list(removePunctuation=TRUE, bounds=list(global=c(10, Inf))))
strPalabras <- dtm$dimnames$Terms

pintaWordClouds(corpus)

rm(corpus, dtm)

write.csv(datos,  file="datos_procesados.csv", row.names=FALSE, quote=TRUE, fileEncoding="UTF-8")

save(strLemas, strPalabras, cmm_lemas, cmm_palabras, asociacion, corpusLemas,  file="environment_datos_procesados.Rda")
