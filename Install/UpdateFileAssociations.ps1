# Update custom file associations with .py handling


function UpdateFileAssocXML ($input, $output) {
    $xml = New-Object -TypeName System.Xml.XmlDocument
    $xml.PreserveWhitespace = $true
    $xml.LoadXml($(Get-Content $input -Raw))
    $defaultAssoc = $xml["DefaultAssociations"]

    # add <Association Identifier=".py" ProgId="Python.File" ApplicationName="Python" />
    $assoc = $xml.CreateElement("Association")
    $assoc.SetAttribute("Identifier", ".py")
    $assoc.SetAttribute("ProgId", "Python.File")
    $assoc.SetAttribute("ApplicationName", "Python")
    $defaultAssoc.AppendChild($xml)

    # Save XML file
    $xml.Save($output)
}

Write-Host "Retrieving current file associations..."
$input = "C:\Install\FileAssocBase.xml"
& Dism /Online /Export-DefaultAppAssociations:$input

Write-Host "Updating file associations..."
$output = "C:\Install\FileAssocUpdated.xml"
UpdateFileAssocXML $input $output 

Write-Host "Applying updated file associations..."
& Dism.exe /online /Import-DefaultAppAssociations:$output
