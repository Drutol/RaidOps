local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("EasyDKP", "deDE" )
if not L then return end
------------
--Example & Info
------------
--[[
	If you want to translate:
	1. Go to enUS.lua in the same folder , this is where all strings are stored.
	2. You want to translate main window title for example.
	3. Find in enUS.lua appropriate key , in this case    -->  "#wndMain:Title"  <--
	4. Copy whole line that is --> L["#wndMain:Title"] = "RaidOps - DKP/EPGP Management"  <--
	5. Paste in deDE.lua or frFR.lua file
	6. Translate the value , that is --> "RaidOps - DKP/EPGP Management" <--
]]

--wndMain
L["#wndMain:Title"] = "RaidOps - DKP/EPGP Manager" 
L["#wndMain:Search"] = "Suche" 
L["#wndMain:Save"] = "Sichern (/reloadui)" 
L["#wndMain:AuctionStart"] = "Start" 
L["#wndMain:CustomAuction"] = "Eigene Auktion" 
L["#wndMain:ShowOnly"] = "Zeige nur" 
L["#wndMain:Hub"] = "Verteiler" 
L["#wndMain:Trading"] = "Handel" 
--wndMain:Labels
L["#wndMain:LabelNumber"] = "Spalten Nr." 
L["#wndMain:LabelName"] = "Name" 
L["#wndMain:LabelNet"] = "Net" 
L["#wndMain:LabelTot"] = "Tot" 
L["#wndMain:LabelHrs"] = "Stunden" 
L["#wndMain:LabelSpent"] = "Ausgegeben" 
L["#wndMain:LabelPriority"] = "Priorität" 
L["#wndMain:LabelRaids"] = "Raids" 
L["#wndMain:LabelLastItem"] = "Letzter Gegenstand" 
L["#wndMain:LabelRealGP"] = "Echte GP"
--LabelTooltips
L["#LabelTooltips:Name"] =  "Spieler Name." 
L["#LabelTooltips:Net"] =  "Gegenwärtige Spieler DKP." 
L["#LabelTooltips:Tot"] =  "Verdiente DKP seit Account Erstellung."
L["#LabelTooltips:Spent"] =  "Ausgegebene Spieler DKP."
L["#LabelTooltips:Hrs"] =  "Wie viel Zeit dieser Spieler geraidet hat. Dies wird automatisch während des Raids erfasst oder optional kann dies im Modul Zeitliche Belohnung erfasst werden."
L["#LabelTooltips:Priority"] =  "Berechneter Wert durch die Teilung von des Tot Betrags durch den Ausgegebenen Betrags. Auch Relation DKP genannt."
L["#LabelTooltips:EP"] =  "Verdienst Punkte (EP) Betrag des Spielers."
L["#LabelTooltips:GP"] =  "Ausrüstung Punkte (GP) des Spielers."
L["#LabelTooltips:PR"] =  "Betrag errechnet sich durch die Teilung von EP durch GP"
L["#LabelTooltips:Raids"] =  "Anzahl der teilgenommenen Raids"
L["#LabelTooltips:Item"] =   "Zuletzt erhaltenes Item. Aufgezeichnet durch Gebote (Chat und Netzwerk)"
L["#LabelTooltips:RealGP"] =  "Aktueller GP Wert abzüglich der Basis GP"
--wndMain:Controls
L["#wndMain:Controls:InputValue"] = "Betrag"
L["#wndMain:Controls:Comment"] = "Kommentar"
L["#wndMain:Controls:Add"] = "Gutschreiben"
L["#wndMain:Controls:Set"] = "Festsetzen"
L["#wndMain:Controls:Sub"] = "Abziehen"
L["#wndMain:Controls:AddToRaid"] = "Dem Raid gutschreiben."
L["#wndMain:Controls:AddPlayer"] = "Spieler hinzufügen"
L["#wndMain:Controls:GroupClass"] = "Nach Klasse sortieren"
L["#wndMain:Controls:NewEntry"] = "Neuer Spielername"
--wndMain:TimedAward
L["#wndMain:TimedAward:CountHRS"] = "Stunden zählen?"
L["#wndMain:TimedAward:Notify"] = "Mitteilen?"
L["#wndMain:TimedAward:Award"] = "Belohnung"
L["#wndMain:TimedAward:Every"] = "Jede"
L["#wndMain:TimedAward:NextAward"] = "Nächste Belohnung in:"
L["#wndMain:TimedAward:Start"] = "Start"
L["#wndMain:TimedAward:Stop"] = "Stop"
L["#wndMain:TimedAward:Disabled"] = "Deaktiviert"
--wndMain:EPGPDecay
L["#wndMain:EPGPDecay:Title"] = "EPGP Verfall"
L["#wndMain:EPGPDecay:DecayEP"] = "EP Verfall"
L["#wndMain:EPGPDecay:DecayGP"] = "GP Verfall"
L["#wndMain:EPGPDecay:By"] = "um:"
L["#wndMain:EPGPDecay:Decay"] = "Verfall"

--wndMain:Tooltips
L["#wndMain:Tooltips:Controls:QuestionMark"] = "Jede Veränderung erfordert einen Kommentar. Man kann dies in den Einstellungen deaktivieren."
L["#wndMain:Tooltips:Controls:GroupTokens"] = "Nach Token Gruppen sortieren."

L["#wndMain:Tooltips:MassEdit:SelectRaid"] = "Raid Teilnehmer auswählen."
L["#wndMain:Tooltips:MassEdit:SelectAll"] = "Alle auswählen."
L["#wndMain:Tooltips:MassEdit:DeselectAll"] = "Alle abwählen."
L["#wndMain:Tooltips:MassEdit:Invite"] = "Ausgewählte einladen."
L["#wndMain:Tooltips:MassEdit:Invert"] = "Auswahl umkehren."
L["#wndMain:Tooltips:MassEdit:Remove"] = "Auswahl entfernen."

L["#wndMain:Tooltips:Refresh"] = "Aktualisieren"
L["#wndMain:Tooltips:Counter"] = "Zeigt die Anzahl der aufgelisteten / ausgewählten Spieler."
L["#wndMain:Tooltips:LLButton"] = "Öffnet das Log für den gesamte Spielerliste."
L["#wndMain:Tooltips:CEButton"] = "Öffnet benutzerdefiniertes Ereignis Log."
L["#wndMain:Tooltips:InvButton"] = "Zeigt Einladung Fenster."
L["#wndMain:Tooltips:GBLButton"] = "Öffnet Gildenbank-Log.."
L["#wndMain:Tooltips:ALButton"] = "Öffnet Aktivitätslog."
L["#wndMain:Tooltips:RaidOnlyButton"] = "Zeigt nur Spieler im Raid an."
L["#wndMain:Tooltips:OnlineOnlyButton"] = "Zeigt nur Online Spieler an (abhängig von der Spielerliste)."
L["#wndMain:Tooltips:MassEditButton"] = "Aktiviert Massenbearbeitung. Jede EP/GP/DKP Veränderung wird sich auf alle markierten Spieler auswirken."
L["#wndMain:Tooltips:RaidQueue"] = "Zeige Raid Warteschlange."
L["#wndMain:Tooltips:ClearRaidQueue"] = "Lösche Raid Warteschlange."

--wndSettings
L["#wndSettings:Title"] = "RaidOps DKP/EPGP Manager Einstellungen"
L["#wndSettings:EnableLogs"] = "Aktiviere Logs"
L["#wndSettings:EnableWhispering"] = "Aktiviere Flüstern"
L["#wndSettings:PlayerCollection"] = "Spieler hinzufügen."
L["#wndSettings:TrackTAUndo"] = "Logge zeitliche Belohnungen."
L["#wndSettings:EnableBidding"] = "Erweitere Carbine's Master Loot addon. Aktivere das Auktions module."
L["#wndSettings:RemInvErr"] = "Entferne Einladungen bei Fehler."
L["#wndSettings:ShowGPTool"] = "Zeige GP Werte im Item Tooltip."
L["#wndSettings:EnableNetworking"] = "Aktiviere Netzwerk"
L["#wndSettings:SkipGPPopUp"] = "Überspringe Gildenbank Abfrage und trage direkt ins Log ein."
L["#wndSettings:PopUpDecrease"] = "Verringere GP um X% in der Abfrage."
L["#wndSettings:EnablePop"] = "Aktiviere Abfrage Fenster"
L["#wndSettings:AllowEquippable"] = "Erlaube nur tragbare Ausrüstung"
L["#wndSettings:FilterCreation"] = "Filter Account erstellung"
L["#wndSettings:LLEnable"] = "Aktiviere Beute Logs."
L["#wndSettings:UndoSave"] = "Sicher das Aktivitätslog zwischen Reloads."
L["#wndSettings:FilteredKeywords"] = "Filterbegriffe."
L["#wndSettings:ColorIcons"] = "Benutze farbliche Klassenzeichen."
L["#wndSettings:DispNumber"] = "Zeige Spielernummer in der Liste."
L["#wndSettings:DispRoles"] = "Zeige Rollensymbole in der Spielerliste."
L["#wndSettings:MECount"] = "Zähle Spieler während der Massenbearbeitung."
L["#wndSettings:PRPrec"] = "Setze PR Nachkommastelle (1-5)"
L["#wndSettings:EPGPPrec"] = "Setze EP / GP Nachkommastelle (1-5)"
L["#wndSettings:FixNames"] = "Berichtige Namen"
L["#wndSettings:StandbyList"] = "Standby Liste"
L["#wndSettings:ImportGuild"] = "Füge Spieler von der Gilde ein."
L["#wndSettings:DataShare"] = "Daten Verteilung"
L["#wndSettings:TrackUndo"] = "Rückgänging Aufzeiuchnung"
L["#wndSettings:Export"] = "Export/Import"
L["#wndSettings:EPGPSettings"] = "EPGP Einstellungen"
L["#wndSettings:Purge"] = "LÖSCHE DATENBANK"
L["#wndSettings:DataSync"] = "Daten Abgleich"
--wndSettings:Tooltips
L["#wndSettings:Tooltips:AccCreation"] = "Account wird nur erstellt wenn der Gildenname identisch zur eigenen Gilde ist."
L["#wndSettings:Tooltips:PopUPDec"] = "Wenn für Zweitbedarf verteilt."
L["#wndSettings:Tooltips:GPTooltip"] = "Um diese Funktion zu nutzen muss das Addon EToolTip installiert und ID Display aktiviert sein."
L["#wndSettings:Tooltips:EnableBidding"] = "Änderung wird erst nach nach /reloadui."
L["#wndSettings:Tooltips:InvErr"] = "Fehler bedeutet alles ausser Akzeptiert / Abgelehnt."
L["#wndSettings:Tooltips:FixNames"] = "Es werden problematische Umlaute und Sonderzeichen entfernt."
L["#wndSettings:Tooltips:Standby"] = "Liste der Spieler die vom Werteverfall ausgeschlossen sind. Sowohl DKP als auch EPGP."
L["#wndSettings:Tooltips:Purge"] = "Lösche Datenbank beim nächsten /reloadui"
--rev 139
L["#wndSettings:Mode"] = "Modus:"
L["#wndSettings:Whitelist"] = "Positivliste"
L["#wndSettings:Blacklist"] = "Negativliste"



