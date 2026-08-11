# Tracker

Native iOS-App (SwiftUI + SwiftData + HealthKit) zum Tracken beliebiger Alltags­aktivitäten – Daylio-artiges Layout, frei konfigurierbare Gruppen/Buttons, Stimmungs-Gate beim App-Start, Statistiken (Balken/Kreis/Heatmap), Schlaf-Daten aus Apple Health, automatisches Backup nach GitHub.

Der alte HTML-Prototyp (`index.html`, `sw.js`, `manifest.json`, `backups/`) bleibt nur als Referenz/Archiv liegen und ist nicht Teil der App.

## 1. Setup in Xcode

1. `Tracker/Tracker.xcodeproj` in Xcode öffnen.
2. **Signing & Capabilities** → Target „Tracker“ → dein Apple-ID-Team unter „Team“ auswählen (aktuell ist keins gesetzt). Ohne Team lässt sich die App nicht auf ein echtes Gerät installieren und die HealthKit-Capability greift nicht.
3. Prüfen, dass unter Signing & Capabilities „HealthKit“ als Capability gelistet ist (wurde bereits über `Tracker.entitlements` eingerichtet) – falls nicht, über „+ Capability“ → „HealthKit“ manuell hinzufügen.
4. Zielgerät wählen: für die meisten Funktionen reicht der Simulator, für **Schlafdaten aus Health** wird ein echtes iPhone mit vorhandenen Schlafdaten benötigt (siehe unten).
5. ⌘R zum Bauen & Starten.

## 2. Erste Schritte in der App

1. Beim ersten Start erscheint sofort das **Stimmungs-Gate** (5 Emojis) – das erscheint ab jetzt bei *jedem* App-Start (auch aus dem Hintergrund), das ist so gewollt.
2. Danach bist du auf dem **Log**-Tab – der ist anfangs leer, das ist Absicht: erst in **Einstellungen → Gruppen verwalten** eine Gruppe anlegen (z. B. „Badezimmer“), dann Buttons hinzufügen (z. B. „Pinkeln“, „Duschen“).
3. Beim Anlegen eines Buttons kannst du festlegen:
   - **Symbol & Farbe**
   - **Modus**: Einmalig (ein Tap = sofort geloggt) oder Zeitspanne (fragt Start-/Endzeit über zwei Zeit-Räder ab, 15-Min-Schritte; Endzeit vor Startzeit = automatisch nächster Tag)
   - **Statistik-Typ**: Balkendiagramm, Heatmap oder keine
   - Bei Heatmap zusätzlich die **max. Häufigkeit/Tag**, die den dunkelsten Farbton auslöst
4. Über „Unterbuttons“ (rechts neben einem Button in der Verwaltung) kannst du z. B. bei „Zocken“ ein Untermenü mit einzelnen Spielen anlegen.
5. Kreisdiagramme werden pro **Gruppe** aktiviert (Gruppe bearbeiten → „Kreisdiagramm anzeigen“).

## 3. Kernfunktionen testen

- **Loggen**: Zurück zum Log-Tab, Button antippen → Eintrag wird sofort erstellt (kurzes haptisches Feedback + kurze 300-ms-Sperre gegen Doppel-Taps).
- **Fuzzy-Suche**: Im Log-Tab oben die Suche nutzen – auch bei Tippfehlern/Teilstrings sollte der passende Button auftauchen.
- **Verlauf**: Einstellungen → „Verlauf“ (oder auf einer Button-Statistik-Seite über „Verlauf anzeigen“) zeigt alle Einträge gruppiert nach Tag; per Wisch löschen, per Antippen Zeit korrigieren.
- **Statistiken**: Stats-Tab → Button auswählen → 3-Panel-Balkendiagramm (7 Tage / Kalenderwochen / 12 Monate, Tippen auf einen Balken zeigt den genauen Wert) bzw. Heatmap mit Monatsnavigation.
- **Stimmung**: Gesundheit-Tab → „Stimmung“ zeigt Wochen-/Monats-/Jahres-Durchschnitt sowie alle Wochentage; Tippen auf einen Kreis zeigt den exakten Wert (2 Nachkommastellen).

## 4. HealthKit testen

1. Einstellungen → „Health verbinden“ antippen, Berechtigungen erteilen (Schreiben: Stimmung, Lesen: Schlaf).
2. Jede neue Stimmungsauswahl wird automatisch als „State of Mind“ nach Apple Health gespiegelt (prüfbar in der Health-App unter „Psychisches Wohlbefinden“).
3. **Schlafdaten** gibt es im Simulator nicht automatisch – dafür ein echtes iPhone (oder iPhone+Watch) mit bereits vorhandenem Schlaf-Tracking verwenden. Im Gesundheit-Tab → „Schlaf“ sollten dann Dauer sowie Ø Einschlaf-/Aufwachzeit erscheinen.
4. Falls ein Stimmungs-Sync mal fehlschlägt, taucht in den Einstellungen ein Button „X Einträge erneut synchronisieren“ auf.

## 5. GitHub-Backup testen

1. Einen **fine-grained Personal Access Token** auf GitHub erstellen, beschränkt auf das Repo `FiniTea/Trackissimo`, mit Schreibrecht auf „Contents“.
2. In den Einstellungen unter „GitHub Backup“ den Token eintragen und speichern (landet im iOS-Schlüsselbund, nirgendwo sonst).
3. Nach jeder Änderung (Log-Eintrag, Stimmung, Bearbeitung) wird automatisch ~2 Sekunden später ein Snapshot nach `backups/tracker.json` im Repo gepusht – lässt sich über „Jetzt sichern“ auch manuell auslösen.
4. „Von GitHub wiederherstellen“ importiert alles, was lokal noch fehlt (rein additiv, überschreibt nichts Bestehendes) – gut zum Testen auf einem zweiten/leeren Gerät.

## 6. Bekannte Einschränkungen

- Deployment-Target ist iOS 18.0 (wegen der `HKStateOfMind`-API für den Mood-Sync).
- Die App ist bewusst Single-User/lokal ausgelegt, kein iCloud-Sync – Backup läuft ausschließlich über GitHub.
- Alte Daten aus dem HTML-Prototyp (`backups/*.json`) wurden bewusst **nicht** importiert – die App startet leer.
