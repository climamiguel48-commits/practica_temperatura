# Sesión práctica — Régimen de Temperatura

Presentación breve con Quarto Reveal.js. Se generan diapositivas mediante `quarto render` en `docs/`, listas para GitHub Pages.

## Contenido
- `index.qmd`: presentación de 8 diapositivas.
- `_quarto.yml`: proyecto website con `output-dir: docs`.
- `slides.css`: estilos.
- `scripts/01_practica_regimen_temperatura_original.R`: archivo entregado por el docente, sin modificaciones.
- `scripts/01_practica_regimen_temperatura.R`: versión sugerida, con lectura del CSV generado y sin paquetes innecesarios; cálculos conservados.

## Ejecución
1. Instalar Quarto y abrir el directorio como proyecto en RStudio.
2. En la terminal: `quarto render` o `quarto preview index.qmd`.
3. Para la actividad R, copiar `scripts/01_practica_regimen_temperatura.R` a la raíz del directorio de trabajo, o ajustar su ruta al invocarlo. El propio script crea `datos/` y `resultados/`.
4. Publicar `docs/` desde la rama `main` en GitHub Pages.

**Atención:** el script original guarda `datos/datos_diarios_2001_2025.csv` pero luego busca `datos/datos_diarios_2001_2025.xlsx`; la versión sugerida lee el CSV correcto. Para usar la opción original, debe existir el XLSX con las columnas requeridas.

Los datos meteorológicos no están incorporados al ZIP: el script los descarga mediante NASA POWER y requiere conexión a internet. No se comprobó aquí la ejecución de R ni el renderizado de Quarto.
