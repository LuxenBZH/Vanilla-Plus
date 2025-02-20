Ext.RegisterConsoleCommand("dumpchar", function()
    Ext.IO.SaveFile("DumpChar.json", Ext.DumpExport(_C()))
end)