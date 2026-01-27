# Update custom file associations with .py handling
# Only affect local user accounts created _after_ the script is run.
# LIMITATION: Does not seem to affect inbuilt LocalService, NetworkService or System accounts - even if running sysprep


function UpdateFileAssocXML ($baseFile, $updatedFile) {
    $xml = New-Object -TypeName System.Xml.XmlDocument
    $xml.PreserveWhitespace = $true
    $xml.LoadXml($(Get-Content $baseFile -Raw))
    $defaultAssoc = $xml["DefaultAssociations"]

    # add <Association Identifier=".py" ProgId="Python.File" ApplicationName="Python" />
    $assoc = $xml.CreateElement("Association")
    $assoc.SetAttribute("Identifier", ".py")
    $assoc.SetAttribute("ProgId", "Python.File")
    $assoc.SetAttribute("ApplicationName", "Python")
    $defaultAssoc.AppendChild($assoc)

    # Save XML file
    $xml.Save($updatedFile)
}

Write-Host "Retrieving current file associations..."
$baseFile = "C:\Install\FileAssocBase.xml"
& Dism /Online /Export-DefaultAppAssociations:$baseFile

Write-Host "Updating file associations..."
$updatedFile = "C:\Install\FileAssocUpdated.xml"
UpdateFileAssocXML $baseFile $updatedFile 

Write-Host "Applying updated file associations..."
& Dism.exe /online /Import-DefaultAppAssociations:$updatedFile
