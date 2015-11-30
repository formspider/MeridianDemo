prerequisites: formspider 1.9

1)create the meridian schema. remember to change the Datasource schema for the Formspider app in the formspider IDE to the correct schema name

2)create (views/triggers/packages) by executing  script meridian-packages.sql

3)import xml to formspider --meridianDemoAppExportFile.xml

4)under Formspider Tomcat Server, create meridianDemo directory under $CATALINA_HOME/webapps/formspider/apps 

5)copy images folder under  'apps/meridianDemo/'
