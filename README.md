# Projekt IZA 2025

Autor: Adam Vožda (xvozdaa00)

## Popis aplikace

TimezoneCalendar je aplikace pro správu událostí napříč různými časovými pásmy. Pomáhá uživatelům organizovat události v globálním kontextu bez nutnosti ručních přepočtů času.

### Architektura a technologie

Aplikace je postavena na architektuře **Model-View-ViewModel (MVVM)**. Pro persistentní ukládání dat využívá **SwiftData**.

### Datové modely

Aplikace pracuje se dvěma datovými modely:

- **Timezone**: Reprezentuje časové pásmo s následujícími atributy:

  - Identifikátor časového pásma
  - Pojmenování pásma
  - Přiřazená barva pro vizuální odlišení

- **Event**: Představuje událost v kalendáři s těmito vlastnostmi:
  - Název události
  - Datum a čas
  - Popis
  - Propojení s konkrétním časovým pásmem

### Hlavní funkcionality

Aplikace nabízí tři klíčové pohledy:

1. **Calendar** - Zobrazení kalendáře, které umožňuje:

   - Procházet události podle vybraného dne
   - Zobrazit detaily jednotlivých událostí
   - Vytvářet události
   - Upravovat události
   - Mazat události

2. **World Clock** - Přehled aktuálních časů ve všech definovaných pásmech:

   - Zobrazení aktuálního času ve všech uložených časových pásmech
   - Přehled nadcházejících událostí v jednotlivých pásmech

3. **Timezones** - Správa časových pásem:
   - Zobrazení seznamu všech definovaných časových pásem
   - Přidávání časových pásem
   - Úprava časových pásem
   - Odstranění časových pásem
