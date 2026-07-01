# PakuMedidas

🇪🇸 README en español · 🇬🇧 [English version](README.en.md)

App Android para anotar fotos de fachadas con cotas y cajas de texto. Diseñada para rotulistas, instaladores y técnicos que necesitan documentar mediciones en campo de forma rápida.

---

## ¿Qué hace?

Toma una foto de cualquier fachada o espacio y añade anotaciones profesionales directamente sobre ella:

- **Cotas** — líneas de dimensión con flechas, valor de medida editable y offset ajustable
- **Cajas de texto** — etiquetas con fondo semitransparente y 4 esquinas libres (forma libre, no solo rectángulos)
- **Exportar JPG** — imagen anotada a resolución completa lista para enviar
- **Exportar PDF vectorial** — cotas y cajas como vectores (no raster), perfectas al hacer zoom en el PDF
- **Compartir** — envío directo por WhatsApp, email o cualquier app

---

## Características

| | |
|---|---|
| Lupa de precisión | Panel 4× al colocar puntos de cota |
| Zoom / Pan | Pinch to zoom + desplazamiento con un dedo |
| Arrastrar todo | Endpoints, texto de cota, offset de línea, esquinas de caja |
| Undo / Redo | 30 pasos de historial |
| Colores | Selector de color para cotas y cajas |
| Proyectos | Lista con thumbnail, renombrar, duplicar, eliminar |
| Offline | Sin servidores, sin internet, funciona 100% local |

---

## Capturas

> *Próximamente*

---

## Requisitos

- Android 5.0 (API 21) o superior
- Permisos: `READ_MEDIA_IMAGES` (galería), `WRITE_EXTERNAL_STORAGE` (Android < 10)

---

## Descargar

El APK está en la página de [releases de GitHub](https://github.com/unmateria/pakuMedidas/releases/latest). Descárgalo, habilita "orígenes desconocidos" si tu dispositivo lo pide, e instálalo.

---

## Compilar desde fuente

Requiere [Basic4Android (B4A)](https://www.b4x.com/b4a.html) v13.3 o superior.

### Librerías necesarias

Instalar desde el B4A Library Manager:
`core`, `xui`, `phone`, `gestures`, `sql`, `json`, `javaobject`

### Build con B4ABuilder (PowerShell)

```powershell
$iniPath  = "$env:APPDATA\Anywhere Software\Basic4android\b4xV5.ini"
$builder  = "C:\Program Files\Anywhere Software\B4A\B4ABuilder.exe"
$folder   = $PSScriptRoot

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $builder
$psi.Arguments = "-Task=Build -BaseFolder=""$folder"" -Project=""pakumedidas.b4a"" -Obfuscate=False -ShowWarnings=True -INI=""$iniPath"""
$psi.WorkingDirectory = $folder
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError  = $true
$psi.UseShellExecute = $false
$p = [System.Diagnostics.Process]::Start($psi)
$p.StandardOutput.ReadToEnd()
$p.WaitForExit(120000)
```

APK de salida: `Objects\pakumedidas.apk`

### Instalar en dispositivo

```bash
adb install -r Objects\pakumedidas.apk
```

---

## Uso rápido

1. Pulsa **+ Nueva** y selecciona una foto de la galería
2. Elige la herramienta **Cota** y toca dos puntos sobre la foto — usa la lupa para precisión
3. Escribe la medida (p. ej. `385 cm`) y pulsa OK
4. Arrastra los extremos, el texto o la línea para ajustar la cota
5. Elige **Caja** para añadir etiquetas de texto con esquinas libres
6. Pulsa **PDF** para exportar o **↗** para compartir directamente

---

## Estructura del proyecto

```
pakumedidas.b4a     — Activity principal + toda la lógica de UI
Starter.bas         — Servicio de inicio + BD SQLite
CotaEngine.bas      — Motor de cotas/cajas: datos, render, hit-test
PdfExporter.bas     — Exportación PDF vectorial nativa (android.graphics.pdf)
```

---

## Licencia

PolyForm Noncommercial 1.0.0 + cláusula de reciprocidad — ver [LICENSE.md](LICENSE.md).

Uso no comercial libre. El uso comercial del original o de cualquier derivado requiere permiso explícito por escrito del autor. Si distribuyes una versión modificada, tiene que seguir siendo abierta bajo esta misma licencia.
