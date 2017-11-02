# Web Scraping páginas de Marca

Proceso de rastreo de las páginas de **Marca** para obtener de su hemeroteca información de artículos publicados e información de estadísticas por jornada.

Hay multitud de sitios web y modos de realizar '***webscraping***'. Para realizar el proceso desde código R, en este proyecto utilizamos el paquete *****rvest***** y nos hemos ayudado de las descripciones que se realizan sobre este paquete en esta página: [beginners guide](https://www.analyticsvidhya.com/blog/2017/03/beginners-guide-on-web-scraping-in-r-using-rvest-with-hands-on-knowledge/).

Para realizar '***webscraping***' se requiere tener unos conocimientos mínimos del lenguaje **HTML** y de como se codifican las páginas web. Normalmente, no queremos la totalidad de información que aparece en una página web y es necesario identificar que partes de la misma queremos sacar. Para el caso de las páginas de **Marca**, nos interesa la información de los diferentes artículos que se incluyen en el diario en cada día de su hemeroteca, concretamente los enlaces a los artículos completos, siendo necesario analizar la estructura de los artículos completos para poder sacar exclusivamente la información del texto de los artículos.

Para ayudar a realizar esta tarea, en la documentación del propio paquete de *****rvest***** aconsejan utilizar un selector de **CSS**, en concreto usar el ***plugin*** [selector gadget](http://selectorgadget.com/) que se incorpora como elemento del navegador **Chrome**.

![Selector CSS](https://github.com/jluqueor/predictor_jornada_liga/blob/master/img/webScrapingSelectorCSS.JPG).

También ayuda explorar el código de la página web, por ejemplo con la funcionalidad **inspeccionar** del mismo navegador.



'''
x <- 13
'''

    x <- 13
