hamburg.freifunk.net Mailserver
===============================

Initiales Setup
-----
1. System starten
2. URL anpassen und aufrufen: http://127.0.0.1/setup.php?lostpw=1
3. Neues Setup-Passwort vergeben und den Hash generieren.
4. Hash in der Datei variables.nix ersetzen und das System neu bauen und starten.
5. URL anpassen und aufrufen: http://127.0.0.1/setup.php
6. Admin-Account über die Website anlegen
7. URL anpassen und aufrufen: http://127.0.0.1/
8. Mail konfigurieren.


Development
-----
Starten des Systems:
    QEMU_NET_OPTS="hostfwd=tcp:127.0.0.1:2222-:22,hostfwd=tcp:127.0.0.1:8080-:80,hostfwd=tcp:127.0.0.1:2525-:25" nixos-shell
Zugriff dann per SSH über 127.0.0.1:2222 und HTTP über 127.0.0.1:8080.
