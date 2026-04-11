# ══════════════════════════════════════════════
# Stage 1 — BUILD
# ══════════════════════════════════════════════
FROM maven:3.9-eclipse-temurin-21-alpine AS build

WORKDIR /app

# Copie du POM et téléchargement des dépendances
COPY pom.xml .
RUN mvn dependency:go-offline -q

# Copie du code source et build
COPY src ./src
RUN mvn clean package -DskipTests -q

# ══════════════════════════════════════════════
# Stage 2 — RUNTIME
# ══════════════════════════════════════════════
FROM eclipse-temurin:21-jre-alpine AS runtime

WORKDIR /app

LABEL maintainer="fello.miage" \
      service="config-server" \
      version="0.0.1-SNAPSHOT"

# Création d'un utilisateur non-root pour la sécurité
RUN addgroup -S odoru && \
    adduser -S odoru -G odoru && \
    mkdir -p /tmp/config-repo && \
    chown -R odoru:odoru /app /tmp/config-repo

# Copie du JAR depuis l'étape de build
COPY --from=build --chown=odoru:odoru /app/target/*.jar app.jar

# Exposition du port
EXPOSE 8888

# Utilisateur non-root
USER odoru

# Configuration JVM optimisée pour les conteneurs
ENTRYPOINT ["java", \
            "-XX:+UseContainerSupport", \
            "-XX:MaxRAMPercentage=75.0", \
            "-XX:+ExitOnOutOfMemoryError", \
            "-Djava.security.egd=file:/dev/./urandom", \
            "-jar", \
            "app.jar"]
