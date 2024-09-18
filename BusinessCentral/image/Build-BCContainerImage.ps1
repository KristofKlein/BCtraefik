# Description: This script is used to create a new BC image with the specified version and country.
$country = "w1"
$version = "23.1"
$type = "OnPrem"
$imageName = "bc"

$myScripts = @("D:\Docker\BusinessCentral\image\my")

new-BCImage -artifactUrl (Get-BCArtifactUrl -type $type -country $country -version $version) -myScripts $myScripts -imageName $imageName -skipDatabase
