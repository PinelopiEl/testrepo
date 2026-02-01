# Use JDK image (necessary for building)
FROM eclipse-temurin:21-jdk-alpine AS build

WORKDIR /app

# Copy gradle files first for caching dependencies
COPY gradlew build.gradle settings.gradle ./
COPY gradle/ gradle/

# Copy source code
COPY src/ src/

# Fix line endings and make gradlew executable
RUN sed -i 's/\r$//' gradlew && chmod +x gradlew

# Build the application
RUN sh gradlew build --exclude-task test

# Runtime stage - use JRE for smaller image
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Copy the built JAR from build stage
COPY --from=build /app/build/libs/*.jar app.jar

EXPOSE 8080

# Run the JAR directly (no need for gradlew in runtime)
ENTRYPOINT ["java", "-jar", "app.jar"]