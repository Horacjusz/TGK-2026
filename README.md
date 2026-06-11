# Mito-mania

Mito-mania to liniowa platformówka logiczno-zręcznościowa, w której kluczem do sukcesu jest współpraca z krabo-podobnymi towarzyszami. Gracz wciela się w postać, która przemierza kolejne poziomy, odnajduje kolejne kraby, a następnie wykorzystuje ich unikalne właściwości do pokonywania przeszkód, unikania pułapek i rozwiązywania zagadek środowiskowych.

- **Gatunek**: Platformówka, 2D
- **Inspiracje**: Ogień i woda, Ori and the blind forest, Bounce Tale

TODO: Zrzuty ekranu

## Użyte narzędzia i platforma

- **Silnik gry**: Godot 4.6
- **Język skryptowy**: GDScript
- **Platformy docelowe**:
  - Web (wersja przeglądarkowa na portalu itch.io)
  - Desktop (systemy Windows, Linux oraz macOS)

## Mechanika

Świat gry jest przedstawiony w przestrzeni dwuwymiarowej (2D) z widokiem z boku (side-scroller). Gra ma charakter całkowicie liniowy – gracz pokonuje z góry zdefiniowaną sekwencję zamkniętych, ograniczonych poziomów. Każdy etap testuje inne zastosowanie odblokowanych towarzyszy.

Kamera podąża za głównym bohaterem lub krabim towarzyszem, w zależności od tego, którą postać kontroluje aktualnie gracz.

Gracz przywołuje wybranego kraba klawiszem F i steruje nim, nagrywając jego trasę. Po upływie czasu (lub ponownym wciśnięciu F) kontrola wraca do gracza, a krab automatycznie odtwarza zapisaną ścieżkę w nieskończonej pętli. Krab staje się fizycznym obiektem służącym jako platforma, tarcza blokująca pociski lub źródło światła (w zależności od wybranego typu towarzysza).

Gracz ma jedno życie – ginie natychmiast po wpadnięciu w przepaść, przeszkodę lub pocisk. Śmierć automatycznie wczytuje ostatni punkt kontrolny (checkpoint), który działa również jako automatyczny zapis stanu gry (autosave).

### Sterowanie

- **WSAD**: Ruch postacią (graczem lub krabem).
- **Spacja**: Skok.
- **E**: Interakcja z otoczeniem (przyciski, dźwignie, portale kończące poziom).
- **1, 2, 3**: Wybór odblokowanego Clankera.
- **F**: Przywołanie kraba i przejęcie nad nim kontroli. Ponowne wciśnięcie F szybciej kończy nagrywanie trasy.
- **R**: Reset i usunięcie kraba ze świata gry.

## Użyte assety

Większość grafiki w projekcie pochodzi z zewnętrznych źródeł dostępnych w sieci. Część assetów została stworzona lub zmodyfikowana własnoręcznie przez zespół.

- **Zewnętrzne paczki**
  - Tiny Metroidvania oraz Tiny Metroidvania – Coral Reef by kenmi → https://kenmi-art.itch.io/metroidvania
  - Caves of Gallet by kaizarnike → https://kaizarnike.itch.io/caves-of-gallet-2
- **Stworzone własnoręcznie**
  - Kraby i ich animacje — Stanisław Barycki
  - UI — Paweł Pruss
  - Dekoracje i pułapki — przygotowane/dopasowane przez zespół

## Wykorzystanie AI

Sztuczna inteligencja została wykorzystana wyłącznie jako wsparcie techniczne przy programowaniu. Nie używano AI do żadnej kreatywnej części projektu.
