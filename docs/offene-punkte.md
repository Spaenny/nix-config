# Offene Punkte

Diese Punkte sind beim Dokumentieren am 2026-11-06 aufgefallen. Es wurde nichts davon geändert. Manche können Absicht sein.

## Klärungsbedarf

**Docker auf `blarm`.** `services.forgejo` schaltet Docker ein, die Konfiguration nutzt es aber nirgends. Einen Forgejo-Runner deklariert das Repository nicht.

**Zed-Agent ohne Rückfragen.** `apps.zed-editor` setzt `always_allow_tool_actions` und `allow_unsandboxed`. Der Agent führt Aktionen damit ohne Bestätigung aus und darf die Sandbox verlassen.

**Formatierung.** Nicht alle Dateien entsprechen dem konfigurierten `nixfmt`. `nix fmt -- --check flake/inventory.nix` meldet zum Beispiel `not formatted`. Der Rest wurde nicht geprüft, und die CI prüft das Format nicht.

**Keine Backups außerhalb von `blarm`.** `aquarius` und `dns` haben kein Restic. Die Zonen und Einstellungen von Technitium liegen nur im Zustandsverzeichnis des Dienstes, außer sie werden dort anderweitig repliziert oder gesichert.

## Nicht genutzte Teile

| Was | Status |
| --- | --- |
| Input `nixos-hardware` | wird nirgends verwendet |
| Input `twitch-hls-client` | wird nicht verwendet, `hardware.audio` nimmt das Paket aus nixpkgs |
| Input `zen-browser` | nur in einem auskommentierten Eintrag in `apps.librewolf` |
| Paket `linkwarden` | kein Modul verwendet es, der Dienst nutzt `pkgs.linkwarden` aus nixpkgs |
| Paket `redlib` | kein Modul verwendet es, der Dienst nutzt `pkgs.redlib` samt Overlay `redlib-fixed` |
| `pkgs.awesome-flake.cinny` | `services.cinny` nutzt standardmäßig `pkgs.cinny-unwrapped` |
| Module `ollama`, `apps.photocraft`, `apps.cinny` | auf keinem Host aktiv |
| `system.sops` auf `aquarius` | aktiv, aber ohne deklarierte Secrets |
