B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Service
Version=13.3
@EndOfDesignText@
#Region Service Attributes
	#StartAtBoot: False
	#ExcludeFromLibrary: True
#End Region

Sub Process_Globals
	Public DB As SQL
End Sub

Sub Service_Create
	DB.Initialize(File.DirInternal, "pakumedidas.db", True)
	DB.ExecNonQuery("CREATE TABLE IF NOT EXISTS projects (" & _
		"id INTEGER PRIMARY KEY AUTOINCREMENT," & _
		"name TEXT NOT NULL," & _
		"image_path TEXT NOT NULL," & _
		"thumb_path TEXT," & _
		"annotations_json TEXT DEFAULT '{""cotas"":[],""textBoxes"":[]}' ," & _
		"created_at INTEGER," & _
		"modified_at INTEGER" & _
		")")
End Sub

Sub Service_Start(StartingIntent As Intent)
	Service.StopAutomaticForeground
End Sub

Sub Service_TaskRemoved
End Sub

Sub Application_Error(Error As Exception, StackTrace As String) As Boolean
	Log("APP ERROR: " & Error.Message)
	Log(StackTrace)
	Return True
End Sub

Sub Service_Destroy
End Sub

Sub AppLog(msg As String)
	Try
		File.MakeDir(File.DirInternal, "logs")
		Dim logDir As String = File.Combine(File.DirInternal, "logs")
		Dim ts As String = DateTime.Date(DateTime.Now) & " " & DateTime.Time(DateTime.Now)
		Dim out As OutputStream = File.OpenOutput(logDir, "pakumedidas.log", True)
		Dim w As TextWriter
		w.Initialize(out)
		w.WriteLine(ts & " - " & msg)
		w.Close
	Catch
	End Try
End Sub
