# Tracker PWA

## Deployment auf GitHub Pages

1. **GitHub Repo erstellen**
   - Gehe zu github.com und erstelle ein neues Repository
   - Name z.B. "tracker" (kann privat oder öffentlich sein)

2. **Dateien hochladen**
   ```bash
   cd tracker-app
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin https://github.com/DEIN-USERNAME/tracker.git
   git push -u origin main
   ```

3. **GitHub Pages aktivieren**
   - Repo Settings → Pages
   - Source: "Deploy from a branch"
   - Branch: main, Ordner: / (root)
   - Save

4. **App installieren**
   - Öffne `https://DEIN-USERNAME.github.io/tracker/` in Safari
   - Teilen-Button → "Zum Home-Bildschirm"

## Icons (optional)

Für ein App-Icon, konvertiere `icon-192.svg` zu PNG:
- Online: https://svgtopng.com
- Oder erstelle eigene 192x192 und 512x512 PNG-Dateien

## Features

- 3 Buttons mit Single/Double-Tap
- Daten werden lokal im Browser gespeichert
- 1-Minute Cooldown gegen versehentliche Mehrfacheinträge
- Grafische Auswertung (7/30 Tage oder alles)
- Funktioniert offline nach erstem Laden
