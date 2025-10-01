FROM mcr.microsoft.com/dotnet/runtime:8.0

ARG RWT_VERSION
ARG RWT_ASSET

ENV TZ=Europe/Berlin \
    DOTNET_EnableDiagnostics=0

# Tools für Download/Entpacken + 'file' zur Architekturprüfung
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl unzip tar file && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Release-Asset laden und entpacken
# URL: https://github.com/RimWorld-Together/Rimworld-Together/releases/download/${RWT_VERSION}/${RWT_ASSET}
RUN test -n "$RWT_VERSION" && test -n "$RWT_ASSET" && \
    echo "Downloading ${RWT_ASSET} from tag ${RWT_VERSION}" && \
    curl -fL -o /tmp/rwt-asset "https://github.com/RimWorld-Together/Rimworld-Together/releases/download/${RWT_VERSION}/${RWT_ASSET}" && \
    (tar -xzf /tmp/rwt-asset -C /app 2>/dev/null || unzip -q /tmp/rwt-asset -d /app) && \
    rm -f /tmp/rwt-asset

# Optional: Sichtprüfung der Architektur, falls 'GameServer' existiert
RUN if [ -f /app/GameServer ]; then echo "GameServer type:" && file /app/GameServer; fi

VOLUME ["/Data"]
EXPOSE 25555/tcp

# Start: erst GameServer (ARM), dann .dll (falls vorhanden)
RUN printf '%s\n' '#!/bin/sh' \
  'set -e' \
  'cd /app' \
  'if [ -x "./GameServer" ]; then' \
  '  exec ./GameServer' \
  'elif [ -x "./RimWorldTogether.Server" ]; then' \
  '  exec ./RimWorldTogether.Server' \
  'elif [ -f "./RimWorldTogether.Server.dll" ]; then' \
  '  exec dotnet ./RimWorldTogether.Server.dll' \
  'else' \
  '  echo "ERROR: Kein Start-Binary gefunden. Inhalt von /app:"' \
  '  ls -la /app' \
  '  exit 1' \
  'fi' > /usr/local/bin/rwt-start && chmod +x /usr/local/bin/rwt-start

CMD ["/usr/local/bin/rwt-start"]
