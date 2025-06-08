FROM openjdk:21
EXPOSE 9092
ADD target/converter.jar converter.jar
ENTRYPOINT ["java", "-jar", "/converter.jar"]