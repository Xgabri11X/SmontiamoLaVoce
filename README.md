# Smontiamo la voce! — Student App v0.2

App Android offline per il laboratorio di acustica: registrazione di una vocale, fondamentale, FFT, armoniche, riconoscimento indicativo A/E/I/O/U, sintesi additiva e spazio vocalico F1–F2 con animazione di bocca e lingua.

## Novità v0.2

- Rimossa la sezione quiz/domande.
- Si può registrare una vocale sostenuta a scelta: **A, E, I, O oppure U**.
- L'app confronta l'inviluppo delle armoniche con modelli vocalici A/E/I/O/U e prova a riconoscere la vocale.
- Il piano F1–F2 parte automaticamente dalla zona della vocale riconosciuta.
- La scomposizione conserva armoniche fino a **20 kHz** (o fino al limite di Nyquist del dispositivo).
- Per leggibilità vengono mostrate solo le prime 24 armoniche, mentre la ricostruzione audio usa l'intero insieme.
- Il morph LPC continua a usare la registrazione reale come sorgente quando disponibile.

## Privacy

La registrazione viene elaborata sul dispositivo. Questa versione non contiene backend, account, analytics o upload audio.

## Funzioni incluse

- Registrazione PCM mono dal microfono.
- Visualizzazione della forma d'onda.
- Stima della fondamentale con YIN e controllo anti-errore d'ottava.
- Spettro 0–5 kHz per la visualizzazione.
- Estrazione armonica fino a 20 kHz per la risintesi.
- Accensione/spegnimento delle armoniche mostrate e risintesi locale.
- Riconoscimento indicativo della vocale A/E/I/O/U dall'inviluppo armonico.
- Piano F1–F2 touch con partenza dalla vocale riconosciuta.
- Bocca e lingua animate in funzione di F1/F2.
- Sintesi LPC dalla voce registrata e sintesi vocalica alternativa.

## Compilazione

Consigliato Flutter stable 3.47.x.

Se la cartella `android/` non esiste ancora:

```bash
./tools/bootstrap_android.sh
```

Poi:

```bash
./tools/build_apk.sh
```

Lo script esegue `flutter pub get`, i test e `flutter build apk --release`. Alla fine troverai:

```text
SmontiamoLaVoce.apk
```

Per provare direttamente su un telefono Android collegato:

```bash
flutter devices
flutter run
```

## Nota sul riconoscimento vocalico

Il riconoscimento è pensato per un laboratorio didattico, non per fonetica clinica. Le formanti dipendono da anatomia, età, sesso, altezza della nota e articolazione. L'app confronta l'inviluppo armonico registrato con regioni rappresentative di A/E/I/O/U e usa la classe più compatibile per scegliere il punto iniziale del trapezio.

## Nota sull'animazione

Il disegno di bocca e lingua è qualitativo: F1 e F2 non determinano in modo univoco la geometria reale del tratto vocale.
