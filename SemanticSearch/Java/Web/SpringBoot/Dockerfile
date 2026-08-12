FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /src
COPY pom.xml .
COPY src/ src/
RUN mvn -B -q -DskipTests package

FROM eclipse-temurin:21-jre-alpine AS runtime
WORKDIR /app
COPY --from=build /src/target/semanticsearch-web-*.jar app.jar
EXPOSE 5000
ENV SPRING_PROFILES_ACTIVE=
ENTRYPOINT ["java", "-jar", "app.jar"]
