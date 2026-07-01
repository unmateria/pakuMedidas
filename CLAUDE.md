# CLAUDE.md — PakuMedidas (B4A Android App)

## PROPÓSITO

App Android para anotar fotos de fachadas con cotas (líneas de dimensión) y cajas de texto
de forma libre. El usuario escribe las medidas manualmente — no hay medición automática.
Pensada para rotulistas, instaladores y técnicos que documentan mediciones en campo.

---

## CÓMO COMPILAR

```powershell
$iniPath = "$env:APPDATA\Anywhere Software\Basic4android\b4xV5.ini"
$builderPath = "C:\Program Files\Anywhere Software\B4A\B4ABuilder.exe"
$baseFolder = $PSScriptRoot
$projectFile = "pakumedidas.b4a"
$args = "-Task=Build -BaseFolder=""$baseFolder"" -Project=""$projectFile"" -Obfuscate=False -ShowWarnings=True -INI=""$iniPath"""

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $builderPath ; $psi.Arguments = $args
$psi.WorkingDirectory = $baseFolder
$psi.RedirectStandardOutput = $true ; $psi.RedirectStandardError = $true
$psi.UseShellExecute = $false ; $psi.CreateNoWindow = $true
$p = New-Object System.Diagnostics.Process
$p.StartInfo = $psi ; $p.Start() | Out-Null
$p.StandardOutput.ReadToEnd() ; $p.StandardError.ReadToEnd()
$p.WaitForExit(120000)
```

APK de salida: `Objects\pakumedidas.apk`

**CRÍTICO**: B4ABuilder debe ejecutarse con `WorkingDirectory` apuntando a la carpeta del
proyecto (la que contiene `pakumedidas.b4a`). Si se lanza desde otro directorio, falla
buscando el `.b4a` en la CWD aunque `BaseFolder` sea correcto.

---

## PROBAR EN EMULADOR (MuMuPlayer)

No hay dispositivo Android físico habitual para pruebas — se usa **MuMuPlayer** (Netease)
como emulador. `adb` no está en el PATH del sistema; hay que usar el `adb.exe` que trae
el propio MuMuPlayer:

```powershell
$adb = "C:\Program Files\Netease\MuMuPlayer\nx_main\adb.exe"
& $adb connect 127.0.0.1:16384   # puerto por defecto de la instancia única de MuMu 12
& $adb devices
```

Si `connect` falla ("conexión denegada"), MuMuPlayer no está abierto — hay que pedir al
usuario que lo abra (no se puede lanzar la GUI de un emulador de forma autónoma). Con
el emulador abierto, el puerto 16384 aparece en `netstat -ano | grep LISTENING`. Una vez
conectado, las tools MCP `b4a_list_devices` / `b4a_install_apk` / `b4a_screenshot` etc. lo
detectan solas (usan el mismo `adb` bajo el capó).

---

## ARQUITECTURA

```
pakumedidas.b4a          — Activity principal (Main)
Starter.bas              — Service: init BD SQLite + globals
CotaEngine.bas           — Motor de datos, render, hit-test y rotación
PdfExporter.bas          — Exportación PDF vectorial
```

### Modelo de datos (JSON en BD)

```json
{
  "cotas": [
    { "x1":100, "y1":200, "x2":500, "y2":200,
      "text":"385 cm", "textOffX":0, "textOffY":-30,
      "cotaOffset":25, "color":-256, "lineWidth":3, "fontSize":14,
      "textAngle":0 }
  ],
  "textBoxes": [
    { "c0x":300, "c0y":400, "c1x":500, "c1y":400,
      "c2x":500, "c2y":460, "c3x":300, "c3y":460,
      "text":"Ventana", "bgColor":-1, "textColor":-16777216,
      "borderColor":-16777216, "fontSize":12 }
  ]
}
```

**TextBox usa 4 esquinas libres** (no x,y,w,h). `LoadFromJson` migra automáticamente
el formato antiguo si detecta clave `"x"`.

**Cota textAngle**: ángulo de rotación del texto (0, 90, 180, 270). `LoadFromJson` migra
cotas antiguas sin `textAngle` asignando 0 por defecto.

---

## DECISIONES TÉCNICAS IMPORTANTES

| Decisión | Motivo |
|----------|--------|
| `JavaObject` para PDF | `android.graphics.pdf.PdfDocument` no está en el SDK de B4A |
| Clases anidadas con `$` | `PdfDocument$PageInfo$Builder`, `Build$VERSION`, `MediaStore$Downloads` |
| `MediaStore.Downloads` para compartir (API≥29) | `FileProvider` con `androidx` falla: la clase no se compila en el DEX. Para API<29 usar StrictMode bypass |
| `Do While n > 0` para copiar bytes | `InputStream.transferTo()` requiere API 33+, no API 29 |
| Guardar P1 antes de resetear | `CotaP1X` se resetea a -1 antes del callback OK; se guardan en `mTextInputP1X/Y` |
| `B4XPath.Initialize(x, y)` | Toma el primer punto como argumento; no existe `MoveTo` separado ni `ClosePath` |
| `inside = (inside = False)` | `Not inside` falla en B4A para Boolean; usar comparación de igualdad |
| `Dim` dentro de bloque `If` | Mover todas las declaraciones al inicio del sub para evitar errores de compilación |
| Float explícito antes de `RunMethod` | Las expresiones aritméticas en B4A se evalúan como Double; los métodos nativos esperan float; declarar variable `As Float` antes de pasar |
| `Bit.And(Action, 255)` en touch | Gestures entrega action sin enmascarar (ej: 261 para POINTER_DOWN con index 1). Hay que aplicar ACTION_MASK = 0xFF |
| `GS.GetX(0)/GetX(1)` para pinch | No usar X,Y del callback para calcular distancia entre dedos: el callback puede dar las coords del pointer que disparó el evento. Siempre usar `GS.GetX(pointerIndex)` |
| Canvas nativo desde B4XCanvas | `bc.Canvas` no existe. Usar `JavaObject(bc).GetFieldJO("cvs").GetFieldJO("canvas")` para obtener `android.graphics.Canvas` |
| `ScreenDensity` para texto rotado | `Paint.setTextSize()` usa píxeles, `CreateDefaultFont()` usa DIP. Multiplicar por `ScreenDensity` en la ruta de texto rotado. Se obtiene lazy via `EnsureDensity` (no en `Initialize`, que no se llama desde `Starter.bas`) |
| `ACTION_SEND_MULTIPLE` para multi-share | Usar `putParcelableArrayListExtra` con `java.util.ArrayList` de URIs |
| Estilo por defecto para cotas | `DefaultCotaColor/LineWidth/FontSize` se actualizan al editar una cota y se usan al crear nuevas |
| Cámara via Intent + StrictMode + JavaObject | `IMAGE_CAPTURE` con `EXTRA_OUTPUT` pasado via `JavaObject.RunMethod("putExtra")` (no `Intent.PutExtra` que no soporta URI). StrictMode bypass para file:// URI |
| `Activity_Resume` para cámara | La cámara lanza una Activity externa; al volver, `Activity_Resume` detecta el archivo temporal y procesa la foto. Si no existe = usuario canceló |
| Listas e init fuera de `If FirstTime` | `SelectedIds`, `UndoStack`, `RedoStack` y `DefaultCotaColor` se inicializan fuera de `If FirstTime` para sobrevivir rotación de pantalla |
| Try-catch en todo `LoadBitmap` | Imágenes corruptas, demasiado grandes o formatos no soportados pueden lanzar excepciones; se muestran toast de error y se aborta la operación |
| Streams con cierre en catch | `CopyToMediaStore` cierra `FileInputStream` y `OutputStream` en el bloque catch para evitar file handle leaks |
| Camera temp con Rnd | `"camera_temp_" & DateTime.Now & "_" & Rnd(0, 9999) & ".jpg"` evita colisión de nombres |
| `RecycleBitmap` via `JavaObject` en `ShowMagnifier` | `Bitmap.Recycle` no está expuesto por el tipo `Bitmap` de B4A. `ShowMagnifier` crea 2 bitmaps nuevos en cada evento de touch-move (varias veces por segundo durante un arrastre); sin reciclar el bitmap anterior el heap nativo se agota (`OutOfMemoryError`) tras arrastres prolongados — se notaba sobre todo al mover esquinas de una caja de texto, que generan arrastres más largos que colocar una cota |

---

## LIBRERÍAS B4A REQUERIDAS

- **core** — básico
- **xui** — B4XCanvas, B4XPath, B4XFont, B4XRect
- **phone** — ContentChooser, Intent
- **gestures** — pinch-to-zoom multi-touch
- **sql** — SQLite
- **json** — JSONParser, JSONGenerator
- **javaobject** — PdfDocument, MediaStore, StrictMode, Matrix, Paint

---

## BD SQLITE

- Fichero: `pakumedidas.db` en `File.DirInternal`
- Tabla: `projects (id, name, image_path, thumb_path, annotations_json, created_at, modified_at)`

---

## FLUJO TOUCH (editor)

```
Canvas_Touch aplica Bit.And(Action, 255) para enmascarar.

Actions manejados:
  0 = ACTION_DOWN          → HandleTouchDown
  5 = ACTION_POINTER_DOWN  → HandlePointerDown (inicia pinch)
  2 = ACTION_MOVE          → HandleTouchMove (pinch, pan, drag, place)
  6 = ACTION_POINTER_UP    → HandlePointerUp (fin pinch)
  1,3 = ACTION_UP/CANCEL   → HandleTouchUp

TouchMode posibles:
  none, pan, pinch,
  place_cota1 / place_cota2,
  drag_endpoint (DragPartIndex: 0=P1, 1=P2),
  drag_text     (desplaza textOffX/Y),
  drag_offset   (mueve la línea de cota perpendicularmente),
  drag_box      (mueve caja entera),
  drag_boxhandle (DragPartIndex: 0-3 = esquinas TL/TR/BR/BL)
```

El pinch zoom funciona en todo momento (incluso durante place_cota). CotaP1X se mantiene
en coordenadas de imagen, no se pierde al hacer zoom.

`drag_boxhandle` y `drag_endpoint` muestran la lupa (magnifier).

Hit-test de endpoints usa tolerancia base 30px con multiplicador 2.0x. También detecta
los puntos en la línea offset (ox1,oy1 / ox2,oy2).

**Desambiguación**: `HitTestAll()` retorna TODOS los elementos bajo el toque. Si hay >1,
se muestra `InputList` con labels ("Cota: 385 cm", "Caja: Ventana") para que el usuario elija.
También se usa en la herramienta Borrar para elegir qué eliminar cuando hay solapamiento.

**Doble-tap**: Si se toca el mismo elemento 2 veces en <400ms, se abre directamente el
editor de texto (sin pasar por long-press → menú).

---

## ROTACIÓN DE IMAGEN

Botones ↻/↺ en la toolbar superior rotan la imagen 90° CW/CCW.

Transformación de coordenadas:
- **90° CW** (oldW×oldH → oldH×oldW): punto `(x,y) → (oldH-y, x)`, vector textOff `(dx,dy) → (-dy, dx)`
- **90° CCW**: punto `(x,y) → (y, oldW-x)`, vector textOff `(dx,dy) → (dy, -dx)`

`RotateImage()` rota bitmap via `android.graphics.Matrix.postRotate`, transforma anotaciones
via `CotaEngine.RotateAll90CW/CCW`, recalcula `BaseScale`, y persiste imagen+thumbnail a disco.

---

## TEXTO ROTADO EN COTAS

El texto de las cotas puede rotarse 90° desde el menú contextual (long-press).
Campo `textAngle` en el modelo (0, 90, 180, 270).

Renderizado:
- **textAngle = 0**: usa `B4XCanvas.DrawText` + `CreateDefaultFont` (DIP)
- **textAngle ≠ 0**: usa canvas nativo `save/rotate/drawText/restore` con `Paint.setTextSize(fs * ScreenDensity)` (píxeles)
- **PDF**: ya usa canvas nativo, aplica `save/rotate/restore` sin multiplicar densidad

---

## EXPORTACIÓN PDF

`PdfExporter.ExportPdf(dir, fileName, bitmap, cotas, textBoxes)`

- Usa `android.graphics.Path` para dibujar cajas como cuadriláteros vectoriales
- Las cotas se dibujan como líneas vectoriales (sin flechas)
- Texto rotado vía `save/rotate/drawText/restore` en el canvas nativo
- La imagen se guarda en `.DirInternal/~pdftmp.jpg` como paso intermedio

---

## COMPARTIR FICHEROS

### Un solo archivo
- API ≥ 29: `CopyToMediaStore` → `MediaStore.Downloads` → URI compartible
- API < 29: `StrictMode.VmPolicy` permisivo + `Uri.fromFile`
- Intent: `ACTION_SEND` con `android.intent.extra.STREAM`
- Streams cerrados en catch de `CopyToMediaStore` para evitar leaks

### Múltiples archivos
- Multi-selección desde la lista de proyectos (long-press → "Seleccionar para compartir")
- Genera PDF para cada proyecto seleccionado
- `GetShareUri()` obtiene URI por proyecto (MediaStore o file://)
- Intent: `ACTION_SEND_MULTIPLE` con `putParcelableArrayListExtra` y `java.util.ArrayList`
- Variables: `MultiSelectMode`, `SelectedIds` (ya declaradas en Globals)

---

## CAPTURA DESDE CÁMARA

- Botón "Foto" en la toolbar de la lista de proyectos
- Lanza `IMAGE_CAPTURE` intent con archivo temporal en DirInternal
- URI pasado via `JavaObject.RunMethod("putExtra")` (B4A `Intent.PutExtra` no soporta Object URI)
- StrictMode bypass para file:// URI (mismo patrón que share en API<29)
- `Activity_Resume` detecta la foto: si el archivo existe, procesa; si no, usuario canceló
- Nombre de archivo temporal incluye `Rnd(0,9999)` para evitar colisiones
- Archivos temporales previos se limpian al lanzar nueva captura

---

## MENÚ CONTEXTUAL DE COTAS

Long-press sobre una cota seleccionada muestra:
1. Editar texto
2. Cambiar color
3. Rotar texto → (+90°)
4. Rotar texto ← (-90°)
5. Tamaño texto (panel visual con presets 8-96 + input custom)
6. Grosor línea (panel visual con presets 1-10)
7. Duplicar
8. Eliminar

## MENÚ CONTEXTUAL DE TEXTBOX

Long-press sobre una caja de texto seleccionada muestra:
1. Editar texto
2. Color fondo
3. Color texto
4. Color borde
5. Tamaño texto (panel visual con presets 8-96 + input custom)
6. Duplicar
7. Eliminar

## PANEL SELECTOR DE TAMAÑO (FontSize / LineWidth)

Panel overlay `pnlFontSize` reutilizable para font size y grosor de línea.
- 2 filas de 5 botones con presets (font: 8,10,12,14,18,24,32,48,64,96 / line: 1,2,3,4,5,6,8,10)
- EditText para valor personalizado (conversión explícita `"" & value`)
- Botón seleccionado se resalta en azul (RGB 33,150,243)
- `ShowLineWidthPanel()` reconfigura los botones con presets de grosor y oculta los 2 últimos
- `RestoreFontSizePresets()` restaura los presets de font al cerrar

## ESTILO POR DEFECTO

- `DefaultCotaColor`, `DefaultCotaLineWidth`, `DefaultCotaFontSize` en Globals
- Se inicializan en `Activity_Create` (fuera de `If FirstTime` para sobrevivir rotación)
- Se actualizan al cambiar color/grosor/font de una cota existente
- Se usan al crear nuevas cotas (en vez de valores hardcoded)

---

## PATRONES DE ROBUSTEZ

| Patrón | Dónde | Por qué |
|--------|-------|---------|
| Try-catch en `LoadBitmap` | CC_Result, OpenEditor, Activity_Resume | Imagen corrupta, OOM, formato no soportado |
| Try-catch en escritura a disco | CC_Result (imagen + thumb) | Disco lleno, permisos |
| Cierre de streams en catch | CopyToMediaStore | Evitar file handle leak si falla la copia |
| `If rs.NextRow Then` + validación | CC_Result, ProcessCameraPhoto | ResultSet vacío no crashea |
| `btnTextInputCancel` check antes de clear | btnTextInputCancel_Click | Reset correcto de TouchMode + CotaP1X al cancelar cota |
| HitTestAll Exit en primer corner | CotaEngine.HitTestAll | Evitar que último corner sobrescriba al primero |
| Init fuera de FirstTime | Activity_Create | Listas y defaults sobreviven rotación de pantalla |
| Camera temp con Rnd + limpieza previa | btnCameraProject_Click | Evitar colisión de nombres y archivos huérfanos |
| `RecycleBitmap` en `ShowMagnifier` | HandleTouchMove (drag_endpoint, drag_boxhandle, place_cota1/2) | Evitar OutOfMemoryError tras arrastres largos (ver tabla de decisiones) |

---

## PUBLICACIÓN

- Repo público: `github.com/unmateria/pakuMedidas` (namespace `unmateria`, mismo que el
  resto de proyectos del usuario). `gh` ya autenticado como `unmateria` en esta máquina.
- Licencia: `LICENSE.md` — **no** es una licencia PolyForm oficial. Es PolyForm
  Noncommercial 1.0.0 (texto oficial verbatim) + una cláusula de reciprocidad/shareback
  redactada a medida (marcada como tal en el propio fichero). Importante para el futuro:
  **no existe ninguna "PolyForm Shareback"** — se comprobó exhaustivamente en
  `polyformproject/polyform-licenses` (todas las ramas/tags) y en `polyformproject.org`;
  si se vuelve a pedir combinar Noncommercial con reciprocidad, la opción real más
  parecida ya evaluada es el par **Prosperity Public License + Parity Public License**
  (License Zero), pero el usuario prefirió la cláusula custom sobre PolyForm Noncommercial.
- Releases: manuales, sin CI. `gh release create vX.Y.Z Objects\pakumedidas.apk --title "..." --notes "..."`.
  Versión actual: v1.0.1 (v1.0.0 tenía el bug de memoria de `ShowMagnifier`, ver tabla de
  decisiones y `PATRONES DE ROBUSTEZ`).
- Ficha en la web personal del usuario: `coletas.es/proyectos/pakumedidas/` (+ versión
  `/en/`), fuente en el repo `coletasWorkshop` (`src/proyectos/pakumedidas.njk` /
  `pakumedidas-en.njk`). Ese repo tiene su propio `CLAUDE.md` con las reglas para
  añadir/editar entradas — consultarlo antes de tocar nada ahí.
