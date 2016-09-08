<!--

-->

Main documentation: http://www.saxonica.com/html/documentation/using-xquery/


examples

java -cp ../bin/Saxon-HE-9.7.0-3.jar  net.sf.saxon.Query  \!method=text -qversion:3.1 -qs:"current-date()"



 java -cp ../bin/Saxon-HE-9.7.0-3.jar  net.sf.saxon.Query  -qversion:3.1
 -qs:"doc('file:///usr/local/eXist/mime-types.xml')//extensions[matches(. , '.xqws,|.xqws$')]"

