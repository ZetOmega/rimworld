FROM mcr.microsoft.com/dotnet/runtime:8.0

ARG RWT_VERSION
ARG RWT_ASSET

ENV TZ=Europe/Berlin \
    DOTNET_EnableDiagnostics=0

# Tools für Download/Entpacken
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl unzip tar && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Release-Asset laden (Tag + Dateiname kommen als Build-Args)
# Beispiel-URL: https://github.com/RimWorld-Together/Rimworld-Together/releases/download/${RWT_VERSION}/${RWT_ASSET}
RUN test -n "$RWT_VERSION" && test -n "$RWT_ASSET" && \
    echo "Downloading ${RWT_ASSET} from tag ${RWT_VERSION}" && \
    curl -fL -o /tmp/rwt-asset "https://github.com/RimWorld-Together/Rimworld-Together/releases/download/${RWT_VERSION}/${RWT_ASSET}" && \
    (tar -xzf /tmp/rwt-asset -C /app 2>/dev/null || unzip -q /tmp/rwt-asset -d /app) && \
    rm -f /tmp/rwt-asset

# Datenordner
VOLUME ["/Data"]

# Standard-Port (TCP). Falls UDP gebraucht wird, in der Compose extra mappen.
EXPOSE 25555/tcp

# Start: zuerst native Binary, sonst DLL via dotnet
RUN printf '%s\n' '#!/bin/sh' \
  'set -e' \
  'cd /app' \
  'if [ -x "./RimWorldTogether.Server" ]; then' \
  '  exec ./RimWorldTogether.Server' \
  'elif [ -f "./RimWorldTogether.Server.dll" ]; then' \
  '  exec dotnet ./RimWorldTogether.Server.dll' \
  'else' \
  '  echo "ERROR: Konnte Server-Binary nicht finden (RimWorldTogether.Server[.dll]). Inhalt von /app:"' \
  '  ls -la /app' \
  '  exit 1' \
  'fi' > /usr/local/bin/rwt-start && chmod +x /usr/local/bin/rwt-start

CMD ["/usr/local/bin/rwt-start"]
