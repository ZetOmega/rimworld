# ---------- Build (holt Upstream & publish ARM64) ----------
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BRANCH=development
ARG RUNTIME_ID=linux-arm64
ARG CONFIGURATION=Release

# Git für Clone
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /src
# Upstream-Source holen (nur den development-Branch)
RUN git clone --depth=1 -b ${BRANCH} https://github.com/RimWorld-Together/Rimworld-Together.git upstream
WORKDIR /src/upstream

# HINWEIS: Pfade können sich ändern. Diese passen derzeit zum Repo (Server-Projekt unter Source/Server)
# Restore + Publish für ARM64 (framework-dependent, nutzt dotnet runtime im nächsten Stage)
RUN dotnet restore Source/Server/RimWorldTogether.Server.csproj && \
    dotnet publish Source/Server/RimWorldTogether.Server.csproj \
      -c ${CONFIGURATION} -r ${RUNTIME_ID} --no-self-contained -o /out

# ---------- Runtime (ARM64) ----------
FROM mcr.microsoft.com/dotnet/runtime:8.0
ENV TZ=Europe/Berlin DOTNET_EnableDiagnostics=0
WORKDIR /app

# Artefakte übernehmen
COPY --from=build /out/ ./

# Datenordner
VOLUME ["/Data"]

# RimWorld Together nutzt Port 25555 (TCP). Falls UDP gebraucht wird, später im Compose mappen.
EXPOSE 25555

# Start (DLL-Name ggf. anpassen, falls im Publish anders)
CMD ["dotnet", "RimWorldTogether.Server.dll"]
