# ---------- Build stage ----------
# Nutzt das .NET SDK, um ARM64-Binaries zu erzeugen
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG PROJECT_PATH="Server/RimWorldTogether.Server.csproj"  # <- ggf. anpassen
ARG CONFIGURATION="Release"
ARG RUNTIME_ID="linux-arm64"

WORKDIR /src

# 1) Source rein
COPY . .

# 2) Restore + Publish für ARM64
RUN dotnet restore "$PROJECT_PATH" \
 && dotnet publish "$PROJECT_PATH" -c "$CONFIGURATION" -r "$RUNTIME_ID" \
    --no-self-contained -o /out

# ---------- Runtime stage ----------
# Schlankes .NET Runtime-Image für ARM64
FROM mcr.microsoft.com/dotnet/runtime:8.0
# Zeit/Locale optional:
ENV TZ=Etc/UTC \
    DOTNET_EnableDiagnostics=0 \
    ASPNETCORE_URLS=http://0.0.0.0:25555

# Workdir im Container
WORKDIR /app

# Artefakte aus dem Buildstage
COPY --from=build /out/ ./

# Falls der Server einen Datenordner nutzt:
VOLUME ["/Data"]

# Expose den Game-Server-Port (TCP – falls UDP benötigt wird, ergänzen)
EXPOSE 25555

# Passe den DLL-Namen an, falls abweichend:
CMD ["dotnet", "RimWorldTogether.Server.dll"]
