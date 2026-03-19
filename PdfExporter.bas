B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=CodeModule
Version=13.3
@EndOfDesignText@
' ════════════════════════════════════════════════════════════════
' PdfExporter — Genera PDF vectorial con imagen + cotas via
' android.graphics.pdf.PdfDocument (API 19+)
' Las cotas y cajas quedan como vectores (no raster)
' ════════════════════════════════════════════════════════════════

Sub Process_Globals
End Sub

' Genera el PDF y lo escribe en dir/fileName
Sub ExportPdf(Dir As String, FileName As String, imgBmp As Bitmap, cotas As List, textBoxes As List)
	Try
		Dim imgW As Int = imgBmp.Width
		Dim imgH As Int = imgBmp.Height

		' ── Crear PdfDocument ──
		Dim pdfDoc As JavaObject
		pdfDoc.InitializeNewInstance("android.graphics.pdf.PdfDocument", Null)

		' ── Crear pagina con dimensiones de imagen ──
		Dim pageInfoBuilder As JavaObject
		pageInfoBuilder.InitializeNewInstance("android.graphics.pdf.PdfDocument$PageInfo$Builder", _
			Array(imgW, imgH, 1))
		Dim pageInfo As JavaObject = pageInfoBuilder.RunMethod("create", Null)
		Dim page As JavaObject = pdfDoc.RunMethod("startPage", Array(pageInfo))
		Dim nativeCanvas As JavaObject = page.RunMethod("getCanvas", Null)

		' ── Dibujar imagen de fondo via BitmapFactory ──
		Dim tmpBmpPath As String = File.Combine(File.DirInternal, "~pdftmp.jpg")
		Dim bmpOut As OutputStream = File.OpenOutput(File.DirInternal, "~pdftmp.jpg", False)
		imgBmp.WriteToStream(bmpOut, 95, "JPEG")
		bmpOut.Close
		Dim bmpFactory As JavaObject
		bmpFactory.InitializeStatic("android.graphics.BitmapFactory")
		Dim rawBitmap As Object = bmpFactory.RunMethod("decodeFile", Array(tmpBmpPath))
		Dim leftF As Float = 0
		Dim topF As Float = 0
		nativeCanvas.RunMethod("drawBitmap", Array(rawBitmap, leftF, topF, Null))

		' ── Crear Paint base ──
		Dim paint As JavaObject
		paint.InitializeNewInstance("android.graphics.Paint", Null)
		paint.RunMethod("setAntiAlias", Array(True))

		' ── Dibujar cajas de texto (4 esquinas libres) ──
		For i = 0 To textBoxes.Size - 1
			Dim m As Map = textBoxes.Get(i)
			Dim c0x As Float = m.Get("c0x") : Dim c0y As Float = m.Get("c0y")
			Dim c1x As Float = m.Get("c1x") : Dim c1y As Float = m.Get("c1y")
			Dim c2x As Float = m.Get("c2x") : Dim c2y As Float = m.Get("c2y")
			Dim c3x As Float = m.Get("c3x") : Dim c3y As Float = m.Get("c3y")
			Dim bgC As Int = m.Get("bgColor")
			Dim txC As Int = m.Get("textColor")
			Dim bdC As Int = m.Get("borderColor")
			Dim fs As Float = m.Get("fontSize")
			Dim txt As String = m.Get("text")

			' Construir path del cuadrilátero
			Dim path As JavaObject
			path.InitializeNewInstance("android.graphics.Path", Null)
			path.RunMethod("moveTo", Array(c0x, c0y))
			path.RunMethod("lineTo", Array(c1x, c1y))
			path.RunMethod("lineTo", Array(c2x, c2y))
			path.RunMethod("lineTo", Array(c3x, c3y))
			path.RunMethod("close", Null)

			' Fondo
			paint.RunMethod("setStyle", Array(GetPaintStyle("FILL")))
			paint.RunMethod("setColor", Array(bgC))
			nativeCanvas.RunMethod("drawPath", Array(path, paint))

			' Borde
			paint.RunMethod("setStyle", Array(GetPaintStyle("STROKE")))
			paint.RunMethod("setColor", Array(bdC))
			paint.RunMethod("setStrokeWidth", Array(2.0))
			nativeCanvas.RunMethod("drawPath", Array(path, paint))

			' Texto en centroide
			Dim tcx As Float = (c0x + c1x + c2x + c3x) / 4
			Dim tcy As Float = (c0y + c1y + c2y + c3y) / 4
			paint.RunMethod("setStyle", Array(GetPaintStyle("FILL")))
			paint.RunMethod("setColor", Array(txC))
			paint.RunMethod("setTextSize", Array(fs))
			paint.RunMethod("setTextAlign", Array(GetTextAlign("CENTER")))
			nativeCanvas.RunMethod("drawText", Array(txt, tcx, tcy + fs / 3, paint))
		Next

		' ── Dibujar cotas ──
		For i = 0 To cotas.Size - 1
			Dim m As Map = cotas.Get(i)
			Dim x1 As Float = m.Get("x1") : Dim y1 As Float = m.Get("y1")
			Dim x2 As Float = m.Get("x2") : Dim y2 As Float = m.Get("y2")
			Dim off As Float = m.Get("cotaOffset")
			Dim textOffX As Float = m.Get("textOffX")
			Dim textOffY As Float = m.Get("textOffY")
			Dim color As Int = m.Get("color")
			Dim lw As Float = Max(1.5, m.Get("lineWidth"))
			Dim fs As Float = m.Get("fontSize")
			Dim txt As String = m.Get("text")

			Dim lineLen As Float = Sqrt(Power(x2 - x1, 2) + Power(y2 - y1, 2))
			If lineLen < 2 Then Continue
			Dim ux As Float = (x2 - x1) / lineLen : Dim uy As Float = (y2 - y1) / lineLen
			Dim nx As Float = -uy : Dim ny As Float = ux
			Dim ox1 As Float = x1 + nx * off : Dim oy1 As Float = y1 + ny * off
			Dim ox2 As Float = x2 + nx * off : Dim oy2 As Float = y2 + ny * off

			paint.RunMethod("setStyle", Array(GetPaintStyle("STROKE")))
			paint.RunMethod("setColor", Array(color))
			paint.RunMethod("setStrokeWidth", Array(lw))
			paint.RunMethod("setStrokeCap", Array(GetStrokeCap("ROUND")))

			' Lineas de extension
			Dim el1x2 As Float = ox1 + nx * 6 : Dim el1y2 As Float = oy1 + ny * 6
			Dim el2x2 As Float = ox2 + nx * 6 : Dim el2y2 As Float = oy2 + ny * 6
			nativeCanvas.RunMethod("drawLine", Array(x1, y1, el1x2, el1y2, paint))
			nativeCanvas.RunMethod("drawLine", Array(x2, y2, el2x2, el2y2, paint))
			nativeCanvas.RunMethod("drawLine", Array(ox1, oy1, ox2, oy2, paint))

			Dim tmx As Float = (ox1 + ox2) / 2 + nx * 18 + textOffX
			Dim tmy As Float = (oy1 + oy2) / 2 + ny * 18 + textOffY

			Dim textAngle As Int = 0
			Dim angleF As Float
			If m.ContainsKey("textAngle") Then textAngle = m.Get("textAngle")
			If textAngle <> 0 Then
				angleF = textAngle
				nativeCanvas.RunMethod("save", Null)
				nativeCanvas.RunMethod("rotate", Array(angleF, tmx, tmy))
			End If

			paint.RunMethod("setStyle", Array(GetPaintStyle("FILL")))
			paint.RunMethod("setColor", Array(Colors.ARGB(160, 0, 0, 0)))
			paint.RunMethod("setTextSize", Array(fs))
			Dim textWidth As Object = paint.RunMethod("measureText", Array(txt))
			Dim tw As Float = textWidth
			Dim rbL As Float = tmx - tw / 2 - 4
			Dim rbT As Float = tmy - fs - 2
			Dim rbR As Float = tmx + tw / 2 + 4
			Dim rbB As Float = tmy + 4
			nativeCanvas.RunMethod("drawRect", Array(rbL, rbT, rbR, rbB, paint))

			paint.RunMethod("setColor", Array(color))
			paint.RunMethod("setTextAlign", Array(GetTextAlign("CENTER")))
			nativeCanvas.RunMethod("drawText", Array(txt, tmx, tmy, paint))

			If textAngle <> 0 Then
				nativeCanvas.RunMethod("restore", Null)
			End If
		Next

		' ── Finalizar pagina ──
		pdfDoc.RunMethod("finishPage", Array(page))

		' ── Escribir a fichero ──
		Dim filePath As String = File.Combine(Dir, FileName)
		Dim fos As JavaObject
		fos.InitializeNewInstance("java.io.FileOutputStream", Array(filePath))
		pdfDoc.RunMethod("writeTo", Array(fos))
		fos.RunMethod("close", Null)
		pdfDoc.RunMethod("close", Null)

		Log("PDF exported: " & filePath)
	Catch
		Log("PdfExporter error: " & LastException)
	End Try
End Sub

Private Sub GetPaintStyle(name As String) As Object
	Dim jo As JavaObject
	jo.InitializeStatic("android.graphics.Paint.Style")
	Return jo.GetField(name)
End Sub

Private Sub GetTextAlign(name As String) As Object
	Dim jo As JavaObject
	jo.InitializeStatic("android.graphics.Paint.Align")
	Return jo.GetField(name)
End Sub

Private Sub GetStrokeCap(name As String) As Object
	Dim jo As JavaObject
	jo.InitializeStatic("android.graphics.Paint.Cap")
	Return jo.GetField(name)
End Sub
