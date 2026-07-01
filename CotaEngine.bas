B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=CodeModule
Version=13.3
@EndOfDesignText@
' ════════════════════════════════════════════════════════════════
' CotaEngine — Datos, renderizado y hit-test de cotas y cajas
' TextBox: 4 esquinas libres (c0=TL,c1=TR,c2=BR,c3=BL, sentido horario)
' ════════════════════════════════════════════════════════════════

Sub Process_Globals
	Private Cotas As List
	Private TextBoxes As List
	Private ScreenDensity As Float
End Sub

' ─── Init / Serialización ─────────────────────────────────────

Sub Initialize
	Cotas.Initialize
	TextBoxes.Initialize
End Sub

Private Sub EnsureDensity
	Dim ctx As JavaObject
	Dim res As JavaObject
	Dim dm As JavaObject
	If ScreenDensity > 0.1 Then Return
	Try
		ctx.InitializeContext
		res = ctx.RunMethod("getResources", Null)
		dm = res.RunMethod("getDisplayMetrics", Null)
		ScreenDensity = dm.GetField("density")
	Catch
	End Try
	If ScreenDensity < 0.1 Then ScreenDensity = 1.0
End Sub

Sub LoadFromJson(jsonStr As String)
	Cotas.Initialize
	TextBoxes.Initialize
	If jsonStr = "" Or jsonStr = Null Then Return
	Try
		Dim parser As JSONParser
		parser.Initialize(jsonStr)
		Dim root As Map = parser.NextObject
		Dim cotaArr As List = root.Get("cotas")
		If cotaArr <> Null Then
			For i = 0 To cotaArr.Size - 1
				Dim cm As Map = cotaArr.Get(i)
				If cm.ContainsKey("textAngle") = False Then cm.Put("textAngle", 0)
				Cotas.Add(cm)
			Next
		End If
		Dim boxArr As List = root.Get("textBoxes")
		If boxArr <> Null Then
			For i = 0 To boxArr.Size - 1
				Dim bm As Map = boxArr.Get(i)
				' Migrar formato antiguo (x,y,w,h) a 4 esquinas libres
				If bm.ContainsKey("x") Then
					Dim bx As Float = bm.Get("x") : Dim by As Float = bm.Get("y")
					Dim bw As Float = bm.Get("w") : Dim bh As Float = bm.Get("h")
					bm.Put("c0x", bx)      : bm.Put("c0y", by)
					bm.Put("c1x", bx + bw) : bm.Put("c1y", by)
					bm.Put("c2x", bx + bw) : bm.Put("c2y", by + bh)
					bm.Put("c3x", bx)      : bm.Put("c3y", by + bh)
				End If
				If bm.ContainsKey("bgColor") = False Then bm.Put("bgColor", Colors.White)
				If bm.ContainsKey("textColor") = False Then bm.Put("textColor", Colors.Black)
				If bm.ContainsKey("borderColor") = False Then bm.Put("borderColor", Colors.Black)
				If bm.ContainsKey("fontSize") = False Then bm.Put("fontSize", 14)
				TextBoxes.Add(bm)
			Next
		End If
	Catch
		Log("CotaEngine.LoadFromJson error: " & LastException)
	End Try
End Sub

Sub ToJson As String
	Dim root As Map
	root.Initialize
	root.Put("cotas", Cotas)
	root.Put("textBoxes", TextBoxes)
	Dim jg As JSONGenerator
	jg.Initialize(root)
	Return jg.ToString
End Sub

' ─── Accesores ────────────────────────────────────────────────

Sub GetCotas As List
	Return Cotas
End Sub

Sub GetTextBoxes As List
	Return TextBoxes
End Sub

' ─── Añadir elementos ─────────────────────────────────────────

Sub AddCota(x1 As Float, y1 As Float, x2 As Float, y2 As Float, _
	text As String, textOffX As Float, textOffY As Float, _
	cotaOffset As Float, color As Int, lineWidth As Float, fontSize As Int, textAngle As Int)
	Dim m As Map
	m.Initialize
	m.Put("x1", x1) : m.Put("y1", y1)
	m.Put("x2", x2) : m.Put("y2", y2)
	m.Put("text", text)
	m.Put("textOffX", textOffX) : m.Put("textOffY", textOffY)
	m.Put("cotaOffset", cotaOffset)
	m.Put("color", color)
	m.Put("lineWidth", lineWidth)
	m.Put("fontSize", fontSize)
	m.Put("textAngle", textAngle)
	Cotas.Add(m)
End Sub

' 4 esquinas libres: c0=TL, c1=TR, c2=BR, c3=BL
Sub AddTextBox(c0x As Float, c0y As Float, c1x As Float, c1y As Float, _
	c2x As Float, c2y As Float, c3x As Float, c3y As Float, _
	text As String, bgColor As Int, textColor As Int, borderColor As Int, fontSize As Int)
	Dim m As Map
	m.Initialize
	m.Put("c0x", c0x) : m.Put("c0y", c0y)
	m.Put("c1x", c1x) : m.Put("c1y", c1y)
	m.Put("c2x", c2x) : m.Put("c2y", c2y)
	m.Put("c3x", c3x) : m.Put("c3y", c3y)
	m.Put("text", text)
	m.Put("bgColor", bgColor)
	m.Put("textColor", textColor)
	m.Put("borderColor", borderColor)
	m.Put("fontSize", fontSize)
	TextBoxes.Add(m)
End Sub

' ─── Getters/Setters ──────────────────────────────────────────

Sub GetCotaText(index As Int) As String
	Return Cotas.Get(index).As(Map).Get("text")
End Sub

Sub SetCotaText(index As Int, text As String)
	Cotas.Get(index).As(Map).Put("text", text)
End Sub

Sub SetCotaColor(index As Int, color As Int)
	Cotas.Get(index).As(Map).Put("color", color)
End Sub

Sub GetTextBoxText(index As Int) As String
	Return TextBoxes.Get(index).As(Map).Get("text")
End Sub

Sub SetTextBoxText(index As Int, text As String)
	TextBoxes.Get(index).As(Map).Put("text", text)
End Sub

Sub SetTextBoxBgColor(index As Int, color As Int)
	TextBoxes.Get(index).As(Map).Put("bgColor", color)
End Sub

Sub SetTextBoxTextColor(index As Int, color As Int)
	TextBoxes.Get(index).As(Map).Put("textColor", color)
End Sub

Sub SetTextBoxBorderColor(index As Int, color As Int)
	TextBoxes.Get(index).As(Map).Put("borderColor", color)
End Sub

Sub SetCotaTextAngle(index As Int, angle As Int)
	Cotas.Get(index).As(Map).Put("textAngle", angle)
End Sub

Sub GetCotaTextAngle(index As Int) As Int
	Dim m As Map = Cotas.Get(index)
	If m.ContainsKey("textAngle") Then Return m.Get("textAngle")
	Return 0
End Sub

Sub SetCotaFontSize(index As Int, fontSize As Int)
	Cotas.Get(index).As(Map).Put("fontSize", fontSize)
End Sub

Sub GetCotaFontSize(index As Int) As Int
	Return Cotas.Get(index).As(Map).Get("fontSize")
End Sub

Sub GetTextBoxFontSize(index As Int) As Int
	Return TextBoxes.Get(index).As(Map).Get("fontSize")
End Sub

Sub SetTextBoxFontSize(index As Int, fontSize As Int)
	TextBoxes.Get(index).As(Map).Put("fontSize", fontSize)
End Sub

Sub GetCotaLineWidth(index As Int) As Int
	Return Cotas.Get(index).As(Map).Get("lineWidth")
End Sub

Sub SetCotaLineWidth(index As Int, lineWidth As Int)
	Cotas.Get(index).As(Map).Put("lineWidth", lineWidth)
End Sub

' ─── Mover / Editar ───────────────────────────────────────────

Sub MoveCotaEndpoint(index As Int, part As Int, ix As Float, iy As Float)
	Dim m As Map = Cotas.Get(index)
	If part = 0 Then
		m.Put("x1", ix) : m.Put("y1", iy)
	Else
		m.Put("x2", ix) : m.Put("y2", iy)
	End If
End Sub

Sub MoveCotaText(index As Int, dx As Float, dy As Float)
	Dim m As Map = Cotas.Get(index)
	m.Put("textOffX", m.Get("textOffX") + dx)
	m.Put("textOffY", m.Get("textOffY") + dy)
End Sub

Sub MoveCotaOffset(index As Int, dx As Float, dy As Float)
	Dim m As Map = Cotas.Get(index)
	Dim x1 As Float = m.Get("x1") : Dim y1 As Float = m.Get("y1")
	Dim x2 As Float = m.Get("x2") : Dim y2 As Float = m.Get("y2")
	Dim lineLen As Float = Sqrt(Power(x2 - x1, 2) + Power(y2 - y1, 2))
	If lineLen < 1 Then Return
	Dim nx As Float = -(y2 - y1) / lineLen
	Dim ny As Float = (x2 - x1) / lineLen
	Dim proj As Float = dx * nx + dy * ny
	m.Put("cotaOffset", m.Get("cotaOffset") + proj)
End Sub

Sub MoveTextBox(index As Int, dx As Float, dy As Float)
	Dim m As Map = TextBoxes.Get(index)
	For i = 0 To 3
		Dim kx As String = "c" & i & "x"
		Dim ky As String = "c" & i & "y"
		m.Put(kx, m.Get(kx) + dx)
		m.Put(ky, m.Get(ky) + dy)
	Next
End Sub

Sub MoveBoxCorner(index As Int, cornerIdx As Int, ix As Float, iy As Float)
	Dim m As Map = TextBoxes.Get(index)
	m.Put("c" & cornerIdx & "x", ix)
	m.Put("c" & cornerIdx & "y", iy)
End Sub

' ─── Duplicar ─────────────────────────────────────────────────

Sub DuplicateCota(index As Int)
	Dim src As Map = Cotas.Get(index)
	Dim m As Map
	m.Initialize
	For Each key As String In src.Keys
		m.Put(key, src.Get(key))
	Next
	m.Put("x1", m.Get("x1") + 20) : m.Put("y1", m.Get("y1") + 20)
	m.Put("x2", m.Get("x2") + 20) : m.Put("y2", m.Get("y2") + 20)
	Cotas.Add(m)
End Sub

Sub DuplicateTextBox(index As Int)
	Dim src As Map = TextBoxes.Get(index)
	Dim m As Map
	m.Initialize
	For Each key As String In src.Keys
		m.Put(key, src.Get(key))
	Next
	For i = 0 To 3
		Dim kx As String = "c" & i & "x"
		Dim ky As String = "c" & i & "y"
		m.Put(kx, m.Get(kx) + 20)
		m.Put(ky, m.Get(ky) + 20)
	Next
	TextBoxes.Add(m)
End Sub

' ─── Eliminar ─────────────────────────────────────────────────

Sub DeleteElement(elemType As String, index As Int)
	If elemType = "cota" Then
		Cotas.RemoveAt(index)
	Else If elemType = "box" Then
		TextBoxes.RemoveAt(index)
	End If
End Sub

' ─── Rotación de imagen ───────────────────────────────────────

Sub RotateAll90CW(oldW As Int, oldH As Int)
	Dim i As Int
	Dim m As Map
	Dim x1 As Float
	Dim y1 As Float
	Dim x2 As Float
	Dim y2 As Float
	Dim tox As Float
	Dim toy As Float
	Dim angle As Int
	Dim cx As Float
	Dim cy As Float
	Dim j As Int
	Dim kx As String
	Dim ky As String
	For i = 0 To Cotas.Size - 1
		m = Cotas.Get(i)
		x1 = m.Get("x1") : y1 = m.Get("y1")
		x2 = m.Get("x2") : y2 = m.Get("y2")
		m.Put("x1", oldH - y1) : m.Put("y1", x1)
		m.Put("x2", oldH - y2) : m.Put("y2", x2)
		tox = m.Get("textOffX") : toy = m.Get("textOffY")
		m.Put("textOffX", -toy) : m.Put("textOffY", tox)
		If m.ContainsKey("textAngle") Then
			angle = m.Get("textAngle")
			angle = angle + 90
			If angle >= 360 Then angle = angle - 360
			m.Put("textAngle", angle)
		End If
	Next
	For i = 0 To TextBoxes.Size - 1
		m = TextBoxes.Get(i)
		For j = 0 To 3
			kx = "c" & j & "x"
			ky = "c" & j & "y"
			cx = m.Get(kx) : cy = m.Get(ky)
			m.Put(kx, oldH - cy)
			m.Put(ky, cx)
		Next
	Next
End Sub

Sub RotateAll90CCW(oldW As Int, oldH As Int)
	Dim i As Int
	Dim m As Map
	Dim x1 As Float
	Dim y1 As Float
	Dim x2 As Float
	Dim y2 As Float
	Dim tox As Float
	Dim toy As Float
	Dim angle As Int
	Dim cx As Float
	Dim cy As Float
	Dim j As Int
	Dim kx As String
	Dim ky As String
	For i = 0 To Cotas.Size - 1
		m = Cotas.Get(i)
		x1 = m.Get("x1") : y1 = m.Get("y1")
		x2 = m.Get("x2") : y2 = m.Get("y2")
		m.Put("x1", y1) : m.Put("y1", oldW - x1)
		m.Put("x2", y2) : m.Put("y2", oldW - x2)
		tox = m.Get("textOffX") : toy = m.Get("textOffY")
		m.Put("textOffX", toy) : m.Put("textOffY", -tox)
		If m.ContainsKey("textAngle") Then
			angle = m.Get("textAngle")
			angle = angle - 90
			If angle < 0 Then angle = angle + 360
			m.Put("textAngle", angle)
		End If
	Next
	For i = 0 To TextBoxes.Size - 1
		m = TextBoxes.Get(i)
		For j = 0 To 3
			kx = "c" & j & "x"
			ky = "c" & j & "y"
			cx = m.Get(kx) : cy = m.Get(ky)
			m.Put(kx, cy)
			m.Put(ky, oldW - cx)
		Next
	Next
End Sub

' ─── Hit-test ─────────────────────────────────────────────────

' Retorna TODOS los elementos que caen dentro de la tolerancia (para desambiguación)
Sub HitTestAll(ix As Float, iy As Float, tolerancePx As Float) As List
	Dim results As List
	results.Initialize
	Dim r As Map

	For i = TextBoxes.Size - 1 To 0 Step -1
		Dim m As Map = TextBoxes.Get(i)
		Dim corners() As Float = GetBoxCorners(m)
		Dim hitCorner As Int = -1
		For h = 0 To 3
			If Dist(ix, iy, corners(h * 2), corners(h * 2 + 1)) < tolerancePx * 1.8 Then
				hitCorner = h
				Exit
			End If
		Next
		If hitCorner >= 0 Then
			r.Initialize
			r.Put("type", "box") : r.Put("index", i)
			r.Put("part", hitCorner) : r.Put("dragMode", "boxhandle")
			r.Put("label", "Caja: " & m.Get("text"))
			results.Add(r)
		Else If PointInQuad(ix, iy, corners(0), corners(1), corners(2), corners(3), _
			corners(4), corners(5), corners(6), corners(7)) Then
			r.Initialize
			r.Put("type", "box") : r.Put("index", i)
			r.Put("part", -1) : r.Put("dragMode", "box")
			r.Put("label", "Caja: " & m.Get("text"))
			results.Add(r)
		End If
	Next

	For i = Cotas.Size - 1 To 0 Step -1
		Dim m As Map = Cotas.Get(i)
		Dim x1 As Float = m.Get("x1") : Dim y1 As Float = m.Get("y1")
		Dim x2 As Float = m.Get("x2") : Dim y2 As Float = m.Get("y2")
		Dim off As Float = m.Get("cotaOffset")
		Dim textOffX As Float = m.Get("textOffX") : Dim textOffY As Float = m.Get("textOffY")
		Dim lineLen As Float = Sqrt(Power(x2 - x1, 2) + Power(y2 - y1, 2))
		If lineLen < 1 Then lineLen = 1
		Dim nx As Float = -(y2 - y1) / lineLen
		Dim ny As Float = (x2 - x1) / lineLen
		Dim ox1 As Float = x1 + nx * off : Dim oy1 As Float = y1 + ny * off
		Dim ox2 As Float = x2 + nx * off : Dim oy2 As Float = y2 + ny * off
		Dim bestDrag As String = ""
		Dim bestPart As Int = -1

		If Dist(ix, iy, x1, y1) < tolerancePx * 2.0 Or Dist(ix, iy, ox1, oy1) < tolerancePx * 2.0 Then
			bestDrag = "endpoint" : bestPart = 0
		Else If Dist(ix, iy, x2, y2) < tolerancePx * 2.0 Or Dist(ix, iy, ox2, oy2) < tolerancePx * 2.0 Then
			bestDrag = "endpoint" : bestPart = 1
		End If
		If bestDrag = "" Then
			Dim tmx As Float = (ox1 + ox2) / 2 + nx * 18 + textOffX
			Dim tmy As Float = (oy1 + oy2) / 2 + ny * 18 + textOffY
			If Dist(ix, iy, tmx, tmy) < tolerancePx * 2.5 Then
				bestDrag = "text" : bestPart = -1
			End If
		End If
		If bestDrag = "" Then
			If DistPointToSegment(ix, iy, ox1, oy1, ox2, oy2) < tolerancePx * 1.5 Then
				bestDrag = "offset" : bestPart = -1
			End If
		End If

		If bestDrag <> "" Then
			r.Initialize
			r.Put("type", "cota") : r.Put("index", i)
			r.Put("part", bestPart) : r.Put("dragMode", bestDrag)
			r.Put("label", "Cota: " & m.Get("text"))
			results.Add(r)
		End If
	Next

	Return results
End Sub

Sub HitTest(ix As Float, iy As Float, tolerancePx As Float) As Map
	Dim result As Map
	result.Initialize
	result.Put("type", "") : result.Put("index", -1)
	result.Put("part", -1) : result.Put("dragMode", "none")

	For i = TextBoxes.Size - 1 To 0 Step -1
		Dim m As Map = TextBoxes.Get(i)
		Dim corners() As Float = GetBoxCorners(m)
		' Esquinas
		For h = 0 To 3
			If Dist(ix, iy, corners(h * 2), corners(h * 2 + 1)) < tolerancePx * 1.8 Then
				result.Put("type", "box") : result.Put("index", i)
				result.Put("part", h) : result.Put("dragMode", "boxhandle")
				Return result
			End If
		Next
		' Interior
		If PointInQuad(ix, iy, corners(0), corners(1), corners(2), corners(3), _
			corners(4), corners(5), corners(6), corners(7)) Then
			result.Put("type", "box") : result.Put("index", i)
			result.Put("part", -1) : result.Put("dragMode", "box")
			Return result
		End If
	Next

	For i = Cotas.Size - 1 To 0 Step -1
		Dim m As Map = Cotas.Get(i)
		Dim x1 As Float = m.Get("x1") : Dim y1 As Float = m.Get("y1")
		Dim x2 As Float = m.Get("x2") : Dim y2 As Float = m.Get("y2")
		Dim off As Float = m.Get("cotaOffset")
		Dim textOffX As Float = m.Get("textOffX") : Dim textOffY As Float = m.Get("textOffY")
		Dim lineLen As Float = Sqrt(Power(x2 - x1, 2) + Power(y2 - y1, 2))
		If lineLen < 1 Then lineLen = 1
		Dim nx As Float = -(y2 - y1) / lineLen
		Dim ny As Float = (x2 - x1) / lineLen
		Dim ox1 As Float = x1 + nx * off : Dim oy1 As Float = y1 + ny * off
		Dim ox2 As Float = x2 + nx * off : Dim oy2 As Float = y2 + ny * off

		If Dist(ix, iy, x1, y1) < tolerancePx * 2.0 Then
			result.Put("type", "cota") : result.Put("index", i)
			result.Put("part", 0) : result.Put("dragMode", "endpoint")
			Return result
		End If
		If Dist(ix, iy, x2, y2) < tolerancePx * 2.0 Then
			result.Put("type", "cota") : result.Put("index", i)
			result.Put("part", 1) : result.Put("dragMode", "endpoint")
			Return result
		End If
		If Dist(ix, iy, ox1, oy1) < tolerancePx * 2.0 Then
			result.Put("type", "cota") : result.Put("index", i)
			result.Put("part", 0) : result.Put("dragMode", "endpoint")
			Return result
		End If
		If Dist(ix, iy, ox2, oy2) < tolerancePx * 2.0 Then
			result.Put("type", "cota") : result.Put("index", i)
			result.Put("part", 1) : result.Put("dragMode", "endpoint")
			Return result
		End If
		Dim tmx As Float = (ox1 + ox2) / 2 + nx * 18 + textOffX
		Dim tmy As Float = (oy1 + oy2) / 2 + ny * 18 + textOffY
		If Dist(ix, iy, tmx, tmy) < tolerancePx * 2.5 Then
			result.Put("type", "cota") : result.Put("index", i)
			result.Put("part", -1) : result.Put("dragMode", "text")
			Return result
		End If
		If DistPointToSegment(ix, iy, ox1, oy1, ox2, oy2) < tolerancePx * 1.5 Then
			result.Put("type", "cota") : result.Put("index", i)
			result.Put("part", -1) : result.Put("dragMode", "offset")
			Return result
		End If
	Next
	Return result
End Sub

Private Sub Dist(x1 As Float, y1 As Float, x2 As Float, y2 As Float) As Float
	Return Sqrt(Power(x2 - x1, 2) + Power(y2 - y1, 2))
End Sub

Private Sub DistPointToSegment(px As Float, py As Float, _
	x1 As Float, y1 As Float, x2 As Float, y2 As Float) As Float
	Dim dx As Float = x2 - x1 : Dim dy As Float = y2 - y1
	Dim lenSq As Float = dx * dx + dy * dy
	If lenSq = 0 Then Return Dist(px, py, x1, y1)
	Dim t As Float = Max(0, Min(1, ((px - x1) * dx + (py - y1) * dy) / lenSq))
	Return Dist(px, py, x1 + t * dx, y1 + t * dy)
End Sub

Private Sub GetBoxCorners(m As Map) As Float()
	Return Array As Float(m.Get("c0x"), m.Get("c0y"), m.Get("c1x"), m.Get("c1y"), _
		m.Get("c2x"), m.Get("c2y"), m.Get("c3x"), m.Get("c3y"))
End Sub

Private Sub PointInQuad(px As Float, py As Float, _
	c0x As Float, c0y As Float, c1x As Float, c1y As Float, _
	c2x As Float, c2y As Float, c3x As Float, c3y As Float) As Boolean
	Dim xs(4) As Float
	xs(0) = c0x : xs(1) = c1x : xs(2) = c2x : xs(3) = c3x
	Dim ys(4) As Float
	ys(0) = c0y : ys(1) = c1y : ys(2) = c2y : ys(3) = c3y
	Dim inside As Boolean
	inside = False
	Dim j As Int
	j = 3
	Dim xIntersect As Float
	For i = 0 To 3
		If (ys(i) > py) <> (ys(j) > py) Then
			xIntersect = (xs(j) - xs(i)) * (py - ys(i)) / (ys(j) - ys(i)) + xs(i)
			If px < xIntersect Then
				inside = (inside = False)
			End If
		End If
		j = i
	Next
	Return inside
End Sub

' ─── Render sobre B4XCanvas (editor) ──────────────────────────

Sub RenderOnB4XCanvas(bc As B4XCanvas, scale As Float, ox As Float, oy As Float, _
	selectedType As String, selectedIdx As Int)

	For i = 0 To TextBoxes.Size - 1
		Dim m As Map = TextBoxes.Get(i)
		Dim c0x As Float = m.Get("c0x") * scale + ox : Dim c0y As Float = m.Get("c0y") * scale + oy
		Dim c1x As Float = m.Get("c1x") * scale + ox : Dim c1y As Float = m.Get("c1y") * scale + oy
		Dim c2x As Float = m.Get("c2x") * scale + ox : Dim c2y As Float = m.Get("c2y") * scale + oy
		Dim c3x As Float = m.Get("c3x") * scale + ox : Dim c3y As Float = m.Get("c3y") * scale + oy
		Dim bgC As Int = m.Get("bgColor")
		Dim txC As Int = m.Get("textColor")
		Dim bdC As Int = m.Get("borderColor")
		Dim fs As Int = m.Get("fontSize")
		Dim txt As String = m.Get("text")

		Dim path As B4XPath
		path.Initialize(c0x, c0y)
		path.LineTo(c1x, c1y)
		path.LineTo(c2x, c2y)
		path.LineTo(c3x, c3y)
		path.LineTo(c0x, c0y)
		bc.DrawPath(path, bgC, True, 0)
		bc.DrawPath(path, bdC, False, Max(1, scale * 1.5))

		Dim cx As Float = (c0x + c1x + c2x + c3x) / 4
		Dim cy As Float = (c0y + c1y + c2y + c3y) / 4
		Dim font As B4XFont = Main.xui.CreateDefaultFont(fs * scale)
		bc.DrawText(txt, cx, cy, font, txC, "CENTER")

		If selectedType = "box" And selectedIdx = i Then
			DrawBoxHandles(bc, c0x, c0y, c1x, c1y, c2x, c2y, c3x, c3y, scale)
		End If
	Next

	For i = 0 To Cotas.Size - 1
		Dim m As Map = Cotas.Get(i)
		Dim x1 As Float = m.Get("x1") * scale + ox
		Dim y1 As Float = m.Get("y1") * scale + oy
		Dim x2 As Float = m.Get("x2") * scale + ox
		Dim y2 As Float = m.Get("y2") * scale + oy
		Dim off As Float = m.Get("cotaOffset") * scale
		Dim textOffX As Float = m.Get("textOffX") * scale
		Dim textOffY As Float = m.Get("textOffY") * scale
		Dim color As Int = m.Get("color")
		Dim lw As Float = Max(1, m.Get("lineWidth") * scale)
		Dim fs As Int = m.Get("fontSize")
		Dim txt As String = m.Get("text")
		Dim textAngle As Int = 0
		If m.ContainsKey("textAngle") Then textAngle = m.Get("textAngle")
		DrawCota(bc, x1, y1, x2, y2, off, textOffX, textOffY, txt, color, lw, fs * scale, textAngle)
		If selectedType = "cota" And selectedIdx = i Then
			bc.DrawCircle(x1, y1, 8 * scale, Colors.White, False, 2)
			bc.DrawCircle(x2, y2, 8 * scale, Colors.White, False, 2)
		End If
	Next
End Sub

Private Sub DrawCota(bc As B4XCanvas, x1 As Float, y1 As Float, x2 As Float, y2 As Float, _
	off As Float, textOffX As Float, textOffY As Float, _
	txt As String, color As Int, lw As Float, fs As Float, textAngle As Int)
	Dim lineLen As Float = Sqrt(Power(x2 - x1, 2) + Power(y2 - y1, 2))
	Dim ux As Float
	Dim uy As Float
	Dim nx As Float
	Dim ny As Float
	Dim ox1 As Float
	Dim oy1 As Float
	Dim ox2 As Float
	Dim oy2 As Float
	Dim extExtra As Float
	Dim tmx As Float
	Dim tmy As Float
	Dim nativeCvs As JavaObject
	Dim paint As JavaObject
	Dim angleF As Float
	Dim bgL As Float
	Dim bgT As Float
	Dim bgR As Float
	Dim bgB As Float
	Dim font As B4XFont
	Dim joBC As JavaObject
	Dim joCvsW As JavaObject
	Dim textSizeF As Float
	If lineLen < 2 Then Return
	ux = (x2 - x1) / lineLen : uy = (y2 - y1) / lineLen
	nx = -uy : ny = ux
	ox1 = x1 + nx * off : oy1 = y1 + ny * off
	ox2 = x2 + nx * off : oy2 = y2 + ny * off
	extExtra = 6
	bc.DrawLine(x1, y1, ox1 + nx * extExtra, oy1 + ny * extExtra, color, lw)
	bc.DrawLine(x2, y2, ox2 + nx * extExtra, oy2 + ny * extExtra, color, lw)
	bc.DrawLine(ox1, oy1, ox2, oy2, color, lw)
	tmx = (ox1 + ox2) / 2 + nx * 18 + textOffX
	tmy = (oy1 + oy2) / 2 + ny * 18 + textOffY
	If textAngle <> 0 Then
		' Texto rotado via canvas nativo (B4XCanvas.cvs → CanvasWrapper.canvas)
		EnsureDensity
		joBC = bc
		joCvsW = joBC.GetFieldJO("cvs")
		nativeCvs = joCvsW.GetFieldJO("canvas")
		paint.InitializeNewInstance("android.graphics.Paint", Null)
		paint.RunMethod("setAntiAlias", Array(True))
		angleF = textAngle
		nativeCvs.RunMethod("save", Null)
		nativeCvs.RunMethod("rotate", Array(angleF, tmx, tmy))
		' Fondo
		paint.RunMethod("setStyle", Array(GetPaintStyleFill))
		paint.RunMethod("setColor", Array(Colors.ARGB(160, 0, 0, 0)))
		textSizeF = Max(8, fs) * ScreenDensity
		bgL = tmx - 30
		bgT = tmy - textSizeF * 0.7
		bgR = tmx + 30
		bgB = tmy + textSizeF * 0.4
		nativeCvs.RunMethod("drawRect", Array(bgL, bgT, bgR, bgB, paint))
		' Texto
		paint.RunMethod("setColor", Array(color))
		paint.RunMethod("setTextSize", Array(textSizeF))
		paint.RunMethod("setTextAlign", Array(GetTextAlignCenter))
		nativeCvs.RunMethod("drawText", Array(txt, tmx, tmy, paint))
		nativeCvs.RunMethod("restore", Null)
	Else
		font = Main.xui.CreateDefaultFont(Max(8, fs))
		bc.DrawRect(CreateRect(tmx - 30, tmy - fs * 0.7, tmx + 30, tmy + fs * 0.4), _
			Colors.ARGB(160, 0, 0, 0), True, 0)
		bc.DrawText(txt, tmx, tmy, font, color, "CENTER")
	End If
End Sub

Private Sub DrawBoxHandles(bc As B4XCanvas, _
	c0x As Float, c0y As Float, c1x As Float, c1y As Float, _
	c2x As Float, c2y As Float, c3x As Float, c3y As Float, scale As Float)
	Dim pts(8) As Float
	pts(0)=c0x : pts(1)=c0y : pts(2)=c1x : pts(3)=c1y
	pts(4)=c2x : pts(5)=c2y : pts(6)=c3x : pts(7)=c3y
	Dim r As Float = Max(6, 7 * scale)
	For i = 0 To 3
		bc.DrawCircle(pts(i*2), pts(i*2+1), r, Colors.White, True, 0)
		bc.DrawCircle(pts(i*2), pts(i*2+1), r, Colors.RGB(33, 150, 243), False, 2)
	Next
End Sub

' ─── Render sobre Canvas clasico (para JPG export) ────────────

Sub RenderOnCanvas(cvs As Canvas, scale As Float, ox As Float, oy As Float, imgW As Int, imgH As Int)
	For i = 0 To TextBoxes.Size - 1
		Dim m As Map = TextBoxes.Get(i)
		Dim c0x As Float = m.Get("c0x") * scale + ox : Dim c0y As Float = m.Get("c0y") * scale + oy
		Dim c1x As Float = m.Get("c1x") * scale + ox : Dim c1y As Float = m.Get("c1y") * scale + oy
		Dim c2x As Float = m.Get("c2x") * scale + ox : Dim c2y As Float = m.Get("c2y") * scale + oy
		Dim c3x As Float = m.Get("c3x") * scale + ox : Dim c3y As Float = m.Get("c3y") * scale + oy
		Dim bdC As Int = m.Get("borderColor")
		Dim txC As Int = m.Get("textColor")
		Dim fs As Float = m.Get("fontSize") * scale
		Dim lw As Float = Max(1, scale * 1.5)
		cvs.DrawLine(c0x, c0y, c1x, c1y, bdC, lw)
		cvs.DrawLine(c1x, c1y, c2x, c2y, bdC, lw)
		cvs.DrawLine(c2x, c2y, c3x, c3y, bdC, lw)
		cvs.DrawLine(c3x, c3y, c0x, c0y, bdC, lw)
		Dim cx As Float = (c0x + c1x + c2x + c3x) / 4
		Dim cy As Float = (c0y + c1y + c2y + c3y) / 4
		cvs.DrawText(m.Get("text"), cx, cy + fs / 3, Typeface.DEFAULT, fs, txC, "CENTER")
	Next

	For i = 0 To Cotas.Size - 1
		Dim m As Map = Cotas.Get(i)
		Dim x1 As Float = m.Get("x1") * scale + ox : Dim y1 As Float = m.Get("y1") * scale + oy
		Dim x2 As Float = m.Get("x2") * scale + ox : Dim y2 As Float = m.Get("y2") * scale + oy
		Dim off As Float = m.Get("cotaOffset") * scale
		Dim textOffX As Float = m.Get("textOffX") * scale
		Dim textOffY As Float = m.Get("textOffY") * scale
		Dim color As Int = m.Get("color")
		Dim lw As Float = Max(1, m.Get("lineWidth") * scale)
		Dim txt As String = m.Get("text")
		Dim fs As Float = m.Get("fontSize") * scale
		Dim lineLen As Float = Sqrt(Power(x2 - x1, 2) + Power(y2 - y1, 2))
		If lineLen < 2 Then Continue
		Dim ux As Float = (x2 - x1) / lineLen : Dim uy As Float = (y2 - y1) / lineLen
		Dim nx As Float = -uy : Dim ny As Float = ux
		Dim ox1 As Float = x1 + nx * off : Dim oy1 As Float = y1 + ny * off
		Dim ox2 As Float = x2 + nx * off : Dim oy2 As Float = y2 + ny * off
		cvs.DrawLine(x1, y1, ox1, oy1, color, lw)
		cvs.DrawLine(x2, y2, ox2, oy2, color, lw)
		cvs.DrawLine(ox1, oy1, ox2, oy2, color, lw)
		Dim tmx As Float = (ox1 + ox2) / 2 + nx * 18 + textOffX
		Dim tmy As Float = (oy1 + oy2) / 2 + ny * 18 + textOffY
		Dim textAngle As Int = 0
		Dim nativeCvs As JavaObject
		Dim paint As JavaObject
		Dim angleF As Float
		Dim joCvsWrapper As JavaObject
		Dim textSizeF As Float
		If m.ContainsKey("textAngle") Then textAngle = m.Get("textAngle")
		If textAngle <> 0 Then
			joCvsWrapper = cvs
			nativeCvs = joCvsWrapper.GetFieldJO("canvas")
			paint.InitializeNewInstance("android.graphics.Paint", Null)
			paint.RunMethod("setAntiAlias", Array(True))
			paint.RunMethod("setColor", Array(color))
			textSizeF = fs
			paint.RunMethod("setTextSize", Array(textSizeF))
			paint.RunMethod("setTextAlign", Array(GetTextAlignCenter))
			angleF = textAngle
			nativeCvs.RunMethod("save", Null)
			nativeCvs.RunMethod("rotate", Array(angleF, tmx, tmy))
			nativeCvs.RunMethod("drawText", Array(txt, tmx, tmy, paint))
			nativeCvs.RunMethod("restore", Null)
		Else
			cvs.DrawText(txt, tmx, tmy, Typeface.DEFAULT, fs, color, "CENTER")
		End If
	Next
End Sub

Private Sub GetPaintStyleFill As Object
	Dim jo As JavaObject
	jo.InitializeStatic("android.graphics.Paint.Style")
	Return jo.GetField("FILL")
End Sub

Private Sub GetTextAlignCenter As Object
	Dim jo As JavaObject
	jo.InitializeStatic("android.graphics.Paint.Align")
	Return jo.GetField("CENTER")
End Sub

Private Sub CreateRect(l As Float, t As Float, r As Float, b As Float) As B4XRect
	Dim rc As B4XRect
	rc.Initialize(l, t, r, b)
	Return rc
End Sub
