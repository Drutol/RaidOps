local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("RaidOps", "deDE" )
if not L then return end
------------
--Example & Info
------------
--[[
If you want to translate:
1. Go to enUS.lua in the same folder , this is where all strings are stored.
2. You want to translate main window title for example.
3. Find in enUS.lua appropriate key , in this case --> "#wndMain:Title" <--
4. Copy whole line that is --> L["#wndMain:Title"] = "RaidOps - DKP/EPGP Management" <--
5. Paste in deDE.lua or frFR.lua file
6. Translate the value , that is --> "RaidOps - DKP/EPGP Management" <--
]]
--wndMain
L["#wndMain:Title"] = "RaidOps - DKP/EPGP Manager"
L["#wndMain:Search"] = "Suche"
L["#wndMain:Save"] = "Speichern (/reloadui)"
L["#wndMain:AuctionStart"] = "Start"
L["#wndMain:CustomAuction"] = "Eigene Auktion"
L["#wndMain:ShowOnly"] = "Auswahl"
L["#wndMain:Hub"] = "Module"
L["#wndMain:Trading"] = "DKP Handel"
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
L["#wndMain:LabelRealGP"] = "Reale GP"
--LabelTooltips
L["#LabelTooltips:Name"] = "Name."
L["#LabelTooltips:Net"] = "Aktuelle DKP."
L["#LabelTooltips:Tot"] = "Verdiente DKP seit Account Erstellung."
L["#LabelTooltips:Spent"] = "Ausgegebene DKP."
L["#LabelTooltips:Hrs"] = "Raidzeit. Diese wird automatisch während des Raids erfasst oder optional im Modul Zeitliche Belohnung erfasst."
L["#LabelTooltips:Priority"] = "Wird durch die Teilung von Tot durch den Ausgegebenen Betrag bestimmt. Auch Relation DKP genannt."
L["#LabelTooltips:EP"] = "Verdiente Punkte (EP)."
L["#LabelTooltips:GP"] = "Ausrüstung Punkte (GP)."
L["#LabelTooltips:PR"] = "Betrag errechnet sich durch die Teilung von EP durch GP"
L["#LabelTooltips:Raids"] = "Anzahl der teilgenommenen Raids"
L["#LabelTooltips:Item"] = "Zuletzt erhaltener Gegenstand. Aufgezeichnet durch Gebote (Chat und Netzwerk)"
L["#LabelTooltips:RealGP"] = "Aktueller GP Wert abzüglich der Basis GP"
--wndMain:Controls
L["#wndMain:Controls:InputValue"] = "Betrag"
L["#wndMain:Controls:Comment"] = "Kommentar"
L["#wndMain:Controls:Add"] = "Hinzufügen"
L["#wndMain:Controls:Set"] = "Festsetzen"
L["#wndMain:Controls:Sub"] = "Abziehen"
L["#wndMain:Controls:AddToRaid"] = "Dem Raid gutschreiben."
L["#wndMain:Controls:AddPlayer"] = "Spieler hinzufügen"
L["#wndMain:Controls:GroupClass"] = "Nach Klasse sortieren"
L["#wndMain:Controls:NewEntry"] = "Neuer Spieler"
--wndMain:TimedAward
L["#wndMain:TimedAward:CountHRS"] = "Stunden zählen?"
L["#wndMain:TimedAward:Notify"] = "Mitteilen?"
L["#wndMain:TimedAward:Award"] = "Belohnung"
L["#wndMain:TimedAward:Every"] = "Jede"
L["#wndMain:TimedAward:NextAward"] = "Nächste Belohnung in:"
L["#wndMain:TimedAward:Start"] = "Start"
L["#wndMain:TimedAward:Stop"] = "Stopp"
L["#wndMain:TimedAward:Disabled"] = "Deaktiviert"
--wndMain:EPGPDecay
L["#wndMain:EPGPDecay:Title"] = "EPGP Verfall"
L["#wndMain:EPGPDecay:DecayEP"] = "EP Verfall"
L["#wndMain:EPGPDecay:DecayGP"] = "GP Verfall"
L["#wndMain:EPGPDecay:By"] = "um:"
L["#wndMain:EPGPDecay:Decay"] = "Verfall"
--wndMain:Tooltips
L["#wndMain:Tooltips:Controls:QuestionMark"] = "Jede Änderung erfordert einen Kommentar. Man kann dies in den Einstellungen deaktivieren."
L["#wndMain:Tooltips:Controls:GroupTokens"] = "Nach Token Gruppen sortieren."
L["#wndMain:Tooltips:MassEdit:SelectRaid"] = "Raid Teilnehmer auswählen."
L["#wndMain:Tooltips:MassEdit:SelectAll"] = "Alle auswählen."
L["#wndMain:Tooltips:MassEdit:DeselectAll"] = "Alle abwählen."
L["#wndMain:Tooltips:MassEdit:Invite"] = "Ausgewählte einladen."
L["#wndMain:Tooltips:MassEdit:Invert"] = "Auswahl umkehren."
L["#wndMain:Tooltips:MassEdit:Remove"] = "Auswahl entfernen."
L["#wndMain:Tooltips:Refresh"] = "Aktualisieren"
L["#wndMain:Tooltips:Counter"] = "Zeigt die Anzahl der aufgelisteten / ausgewählten Spieler."
L["#wndMain:Tooltips:LLButton"] = "Öffnet das Protokoll für den gesamte Liste."
L["#wndMain:Tooltips:CEButton"] = "Öffnet benutzerdefiniertes Ereignis Protokoll."
L["#wndMain:Tooltips:InvButton"] = "Zeigt Einladung Fenster."
L["#wndMain:Tooltips:GBLButton"] = "Öffnet Gildenbank-Protokoll.."
L["#wndMain:Tooltips:ALButton"] = "Öffnet Aktivität-Protokoll."
L["#wndMain:Tooltips:RaidOnlyButton"] = "Zeigt nur Spieler im Raid an."
L["#wndMain:Tooltips:OnlineOnlyButton"] = "Zeigt nur Online Spieler an (abhängig von der Spielerliste)."
L["#wndMain:Tooltips:MassEditButton"] = "Aktiviert Massenbearbeitung. Jede EP/GP/DKP Veränderung wirkt sich auf alle markierten Spieler aus."
L["#wndMain:Tooltips:RaidQueue"] = "Zeige Raid Warteschlange."
L["#wndMain:Tooltips:ClearRaidQueue"] = "Lösche Raid Warteschlange."
--wndSettings
L["#wndSettings:Title"] = "RaidOps DKP/EPGP Manager Einstellungen"
L["#wndSettings:EnableLogs"] = "Aktiviere Protokolle"
L["#wndSettings:EnableWhispering"] = "Aktiviere Flüstern"
L["#wndSettings:PlayerCollection"] = "Spieler hinzufügen."
L["#wndSettings:TrackTAUndo"] = "Protokolliere zeit bedingte Belohnungen."
L["#wndSettings:EnableBidding"] = "Erweitere Carbine's Master Loot Addon. Aktivere das Auktion Modul."
L["#wndSettings:RemInvErr"] = "Entferne Einladungen bei Fehler."
L["#wndSettings:ShowGPTool"] = "Zeige GP Werte im der Gegenstands Information."
L["#wndSettings:EnableNetworking"] = "Aktiviere Netzwerk"
L["#wndSettings:SkipGPPopUp"] = "Überspringe Gildenbank Abfrage und trage direkt ins Protokoll ein."
L["#wndSettings:PopUpDecrease"] = "Verringere GP um X% in der Abfrage."
L["#wndSettings:EnablePop"] = "Aktiviere Abfrage Fenster"
L["#wndSettings:AllowEquippable"] = "Erlaube nur tragbare Ausrüstung"
L["#wndSettings:FilterCreation"] = "Filter Account Erstellung"
L["#wndSettings:LLEnable"] = "Aktiviere Beute Protokolle."
L["#wndSettings:UndoSave"] = "Sicher das Aktivität Protokoll zwischen Reloads."
L["#wndSettings:FilteredKeywords"] = "Suchwörter."
L["#wndSettings:ColorIcons"] = "Benutze farbliche Klassenzeichen."
L["#wndSettings:DispNumber"] = "Zeige Spielernummer in der Liste."
L["#wndSettings:DispRoles"] = "Zeige Rollensymbole in der Spielerliste."
L["#wndSettings:MECount"] = "Zähle Spieler während der Massenbearbeitung."
L["#wndSettings:PRPrec"] = "Setze PR Nachkommastelle (1-5)"
L["#wndSettings:EPGPPrec"] = "Setze EP / GP Nachkommastelle (0-5)"
L["#wndSettings:FixNames"] = "Berichtige Namen"
L["#wndSettings:StandbyList"] = "Inaktive  Liste"
L["#wndSettings:ImportGuild"] = "Füge Spieler von der Gilde ein."
L["#wndSettings:DataShare"] = "Daten Verteilung"
L["#wndSettings:TrackUndo"] = "Aufzeichnen zum Rückgängig machen"
L["#wndSettings:Export"] = "Export/Import"
L["#wndSettings:EPGPSettings"] = "EPGP Einstellungen"
L["#wndSettings:Purge"] = "LÖSCHE DATENBANK"
L["#wndSettings:DataSync"] = "Daten Abgleich"
--wndSettings:Tooltips
L["#wndSettings:Tooltips:AccCreation"] = "Account wird nur erstellt wenn der Gildenname identisch zur eigenen Gilde ist."
L["#wndSettings:Tooltips:PopUPDec"] = "Wenn für Zweitbedarf verteilt."
L["#wndSettings:Tooltips:GPTooltip"] = "Um diese Funktion zu nutzen muss das Addon EToolTip installiert und ID Display aktiviert sein."
L["#wndSettings:Tooltips:EnableBidding"] = "Änderung wird erst nach /reloadui aktiv"
L["#wndSettings:Tooltips:InvErr"] = "Fehler sind alles außer Akzeptiert / Abgelehnt."
L["#wndSettings:Tooltips:FixNames"] = "Es werden problematische Umlaute und Sonderzeichen entfernt."
L["#wndSettings:Tooltips:Standby"] = "Liste der Spieler die vom Werteverfall ausgeschlossen sind. Sowohl DKP als auch EPGP."
L["#wndSettings:Tooltips:Purge"] = "Lösche Datenbank beim nächsten /reloadui"
--rev 139
L["#wndSettings:Mode"] = "Modus:"
L["#wndSettings:Whitelist"] = "Positiv Liste"
L["#wndSettings:Blacklist"] = "Negativ Liste"
--rev 140
L["#wndSettings:Tooltips:FilterKey"] = "Wortliste getrennt durch ; für die Positiv- oder Negativ Liste."
--rev 141
L["#wndSettings:SkipGPPopUpAssign"] = "Überspringe EPGP Eingabe bei Zufallsverteilung"
--wndBid
L["#wndBid:Title"] = "Chat Auktion"
L["#wndBid:Link"] = "Zeige im Chat"
L["#wndBid:CountDown"] = "Restzeit(s)"
L["#wndBid:StartBid"] = "Starte Auktion"
L["#wndBid:StopBid"] = "Stopp"
L["#wndBid:Assign"] = "Zuteilen"
L["#wndBid:Select"] = "Auswahl"
L["#wndBid:LastWinnerTitle"] = "Zuletzt gewonnener Gegenstand:"
L["#wndBid:LastWinnerBy"] = "Von:"
L["#wndBid:Modes:Title"] = "Modus:"
L["#wndBid:Modes:AllowOffspec"] = "Erlaube Zweitbedarf"
L["#wndBid:Modes:roll"] = "Würfeln"
L["#wndBid:Modes:mroll"] = "Angepasstes Würfeln"
L["#wndBid:Modes:odkp"] = "Offenes DKP"
L["#wndBid:Modes:hdkp"] = "Geheimes DKP"
L["#wndBid:Modes:SettingsTitle"] = "Modus Einstellungen:"
L["#wndBid:Modes:ModRollTitle"] = "Angepasstes Würfeln: Modifikation + X% der EP"
L["#wndBid:Modes:SettingsGuild"] = "Gilde"
L["#wndBid:Modes:SettingsParty"] = "Gruppe"
L["#wndBid:Modes:EPGPoffspecTitle"] = "Verringere EPGP Zweitbedarf PR um:"
L["#wndBid:Modes:BidChannel"] = "Auktion Chatkanal:"
L["#wndBid:Modes:overbid"] = "Minimales Überbieten:"
L["#wndBid:Modes:minbid"] = "Minimales Gebot:"
L["#wndBid:Modes:DKPSettings"] = "DKP Auktion Einstellungen:"
L["#wndBid:Modes:WhispRespond"] = "Erwiderung per Flüstern."
--BidStrings
L["#biddingStrings:DKPOpen"] = " [Chat Auktion] Offene Auktion gestartet für %s , um teilzunehmen schreibe Dein DKP Gebot in den %s Chatkanal. Mindestgebot: %s"
L["#biddingStrings:DKPHidden"] = " [Chat Auktion] Geheime Auktion gestartet für %s , um teilzunehmen flüstere Dein DKP Gebot an: %s . Mindestgebot: %s"
L["#biddingStrings:roll"] = " [Chat Auktion] Schreibe /würfeln um an der Auktion für %s teilzunehmen."
L["#biddingStrings:modifiedRoll"] = " [Chat Auktion] Schreibe /würfeln um an der Auktion für %s teilzunehmen. Dies ist ein angepasstes Würfeln : %s Prozent deiner EP wird zu deinem Wurf addiert."
L["#biddingStrings:EPGP"] = " [Chat Auktion] Um an der Auktion für %s teilzunehmen schreibe !bid in %s Chatkanal. Schreibe erneut !bid um abzubrechen"
L["#biddingStrings:EPGPoffspec"] = " [Chat Auktion] Hinweis: Zweitbedarf Auktion ist aktiv, für Zweitbedarf schreibe !off . Zweitbedarf PR wird um %s Prozent verringert. Schreibe erneut !off um abzubrechen"
L["#biddingStrings:AuctionEndWinner"] = " [Chat Auktion] Auktion beendet , %s hat gewonnen."
L["#biddingStrings:AuctionEnd"] = " [Chat Auktion] Auktion ohne Gewinner beendet."
L["#biddingStrings:AuctionEndEarly"] = " [Chat Auktion] Auktion vorzeitig beendet , %s hat gewonnen."
--EPGPSettings
L["#wndEPGPSettings:Title"] = "EPGP Einstellungen"
L["#wndEPGPSettings:Enable"] = "Aktivieren "
L["#wndEPGPSettings:itemcosttitle"] = "Gegenstandskosten:"
L["#wndEPGPSettings:ItemCost:Weapon"] = "Waffen"
L["#wndEPGPSettings:ItemCost:Shield"] = "Schild"
L["#wndEPGPSettings:ItemCost:Head"] = "Kopf"
L["#wndEPGPSettings:ItemCost:Shoulders"] = "Schultern"
L["#wndEPGPSettings:ItemCost:Chest"] = "Brust"
L["#wndEPGPSettings:ItemCost:Hands"] = "Hände"
L["#wndEPGPSettings:ItemCost:Legs"] = "Beine"
L["#wndEPGPSettings:ItemCost:Feet"] = "Füße"
L["#wndEPGPSettings:ItemCost:Attachment"] = "Waffenmodule"
L["#wndEPGPSettings:ItemCost:Support"] = "Unterstützungssysteme"
L["#wndEPGPSettings:ItemCost:Gadget"] = "Apparatur"
L["#wndEPGPSettings:ItemCost:Implant"] = "Implantat"
L["#wndEPGPSettings:ItemCost:OQual"] = "Orange Qualität"
L["#wndEPGPSettings:ItemCost:PQual"] = "Lila Qualität"
L["#wndEPGPSettings:ItemCost:Formula"] = "Gegenstandskosten =(Gegenstandswert / Qualität) * Modifikation * Ausrüstungsplatz"
L["#wndEPGPSettings:DecayReal"] = "Verfall Real GP"
L["#wndEPGPSettings:GPMin"] = "Verhindere GP kleiner als 1."
L["#wndEPGPSettings:RoundDecay"] = "Benutze gerundete Werte für den Verfall."
L["#wndEPGPSettings:Reset"] = "Zurücksetzen"

--rev 145
L["#wndSettings:MinIlvl"] = "Mindest-Gegenstand-Stufe"
L["#wndSettings:FilteredQual"] = "Gegenstandsqualitätsfilter" -- i love this one :D
--rev 146
L["#wndBid:Mainspec"] = "Hauptskillung"
L["#wndBid:Offspec"] = "Nebenskillung"
L["#wndBid:Modes:ShortMsg"] = "Kurze Benachrichtigung"
L["#biddingStrings:short:DKPOpen"] = " [Text Auktion] Ihr bietet auf %s , schreibt das DKP Gebot in %s "
L["#biddingStrings:short:DKPHidden"] = " [Text Auktion] Ihr bietet auf %s , um teilzunehmen flüstet euer DKP Gebot an : %s ."
L["#biddingStrings:short:EPGP"] = " [Text Auktion] Gegenstand : %s , schreibe %s um dein Gebot zu setzen, schreibe es erneut zum entfernen!"
--rev 147
L["#wndSettings:AutoComment"] = "Erstelle Kommentare automatisch"
--v2.02
L["#wndBid:Modes:AutoSelect"] = "Bestimme den Gewinner automatisch"
--v2.03
L["#wndSettings:SkipBidWinner"] = "Verberge das Pop-up Fenster, wenn durch eine Auktion gewonnen wurde."
--v2.04
L["#wndBid:Modes:AutoStart"] = "Starte Auktion automatisch."
--v2.05
L["#wndSettings:RaidInvites"] = "Raid Einladungen."
--v2.15
L["#LabelTooltips:%GA"] = "Prozentuale Teilnahme an GA Raids."
L["#LabelTooltips:%DS"] = "Prozentuale Teilnahme an DS Raids."
L["#LabelTooltips:%Y"] = "Prozentuale Teilnahme an Y-83 Raids."
L["#LabelTooltips:%Total"] = "Prozentuale Teilnahme an allen Raidss."
L["#LabelTooltips:GA"] = "Verhältnis der teilgenommenen GA Raids zu allen GA Raids."
L["#LabelTooltips:DS"] = "Verhältnis der teilgenommenen DS Raids zu allen DS Raids."
L["#LabelTooltips:Y"] = "Verhältnis der teilgenommenen Y-83 Raids zu allen Y-83 Raids."
L["#LabelTooltips:Total"] = "Prozentualle Teilnahme an allen Raids."
--v2.20
L["#wndEPGPSettings:GPThres"] = "GP kann nicht unter die Grund GP Fallen."
--v2.22
L["#wndMain:TimedAward:NotifyScreen"] = "Benachrichtung auf dem Monitor ?"
--v2.23 and a half
L["#wndSettings:ItemLabelFilter"] = "Filter Item Bezeichnung mit Loot Logs Filterung."
--v2.25
L["#wndMain:DKPDecay:Title"] = "DKP Verfall"
L["#wndMain:DKPDecay:MinNet"] = "Minimaler Net Betrag:"
L["#wndMain:DKPDecay:HelpNegative"] = "Negativer DKP Zuwachs."
L["#wndSettings:DKPPrec"] = "Setzte DKP Präzision."
L["#wndEPGPSettings:Enable"] = "Aktiviere EPGP"
--v2.26
L["#wndBid:AssignRandom"] = "Zufällige Verteilung"



L["#wndCE:NotifyDur"] = "Notification's Duration:(in german)"


-- Internal strings
L["#Imprint"] = "Prägung"

L["#Chestplate"] = "Brust"
L["#Greaves"] = "Beine"
L["#Pauldron"] = "Schulter"
L["#Glove"] = "Hände"
L["#Boot"] = "Füße"
L["#Helm"] = "Kopf"

L["#Calculated"] = "Berechnet"
L["#Algebraic"] = "Algebraisch"
L["#Logarithmic"] = "Logarithmisch"

L["#Xenological"] = "Xenological"
L["#Xenobiotic"] = "Xenobiotic"
L["#Xenogenetic"] = "Xenogenetic"

L["#PhagetechCommander"] = "Phagentech-Kommandant"
L["#PhagetechAugmentor"] = "Phagentech-Augmentor"
L["#PhagetechProtector"] = "Phagentech-Protektor"
L["#PhagetechFabricator"] = "Phagentech-Fabrikant"
L["#ErsothCurseform"] = "Ersoth Fluchform"
L["#FleshmongerVratorg"] = "Fleischhändler Vratorg"
L["#TerexBlightweaver"] = "Terax Faulflechter"
L["#GolgoxtheLifecrusher"] = "Golgox der Lebenszermalmer"
L["#NoxmindtheInsidious"] = "Noxgeist der Hinterlistige"
L["#BinarySystemDaemon"] = "Binärsystem-Dämon"
L["#NullSystemDaemon"] = "Nullsystem-Dämon"

L["#Experiment X-89"] = "Experiment X-89"
L["#KuralaktheDefiler"] = "Kuralak die Schänderin"
L["#PhageMaw"] = "Phagenschlund"
L["#PhagebornConvergence"] = "Konvergenz der Phagengeborenen"
L["#PhagetechPrototypes"] = "Phagentech Prototypen"
L["#DreadphageOhmna"] = "Schreckensphage Ohmna"
L["#SystemDaemons"] = "System-Dämonen"
L["#Gloomclaw"] = "Düsterklaue"
L["#MaelstormAuthority"] = "Mahlstromgewalt"
L["#VolatilityLattice"] = "Explosionsraster"
L["#Avatus"] = "Avatus"

--v2.34b
L["#LimboInfo"] = "Limbus-Infomatrix"
