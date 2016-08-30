$defaultFile="default.csv"

$updatedRecordsFile="updates.csv"

$folderToCheck="C:\\Users\\test\\Desktop\\abc"
$folderToUpdate="C:\Users\test\Desktop\abc2"

$excluded = @("*.log", "*log*", "bla.xml")


function checkAndCreateNewFiles() {
	Param([hashtable] $default_configuration, [hashtable]$updated_configuration)
	
	foreach ($loop in $updated_configuration.GetEnumerator()) {
		
		$isNewFileNotFound=!($default_configuration.ContainsKey($($loop.Name)))
		$isOldFileNotUpdated=!($default_configuration.Get_Item($($loop.Name)) -Match $loop.Value)
		
		if($isNewFileNotFound -Or $isOldFileNotUpdated){
			$sourceName=$loop.Name -replace '"', ""
			
			$destinationFile=$loop.Name -replace $folderToCheck, $folderToUpdate
			$destinationFile=$destinationFile -replace '"', ""
			
			$destinationFolder=$destinationFile.Substring(0,$destinationFile.LastIndexOf("\"));
			
			if (!(Test-Path -path $destinationFolder)) {New-Item $destinationFolder -Type Directory}
			
			Copy-Item $sourceName -Destination $destinationFolder -Recurse -Force
			Write-Host "creating new file [$($destinationFile)]"
		}
	}
}

function checkAndRemoveMissingFiles(){
	Param([hashtable] $default_configuration, [hashtable]$updated_configuration)
	foreach ($loop in $default_configuration.GetEnumerator()) {
		
		$isOldFileNotFound=!($updated_configuration.ContainsKey($($loop.Name)))
		
		if($isOldFileNotFound){
			
			$destinationFile=$loop.Name -replace $folderToCheck, $folderToUpdate
			$destinationFile=$destinationFile -replace '"', ""
			
			Remove-Item -Path $destinationFile -Recurse -Force
			Write-Host "deleting removed file [$($destinationFile)]"
		}
	}
}

function createACSVOfNewFiles(){
	get-childitem -path $folderToCheck -recurse -exclude $excluded | where {!$_.PSIsContainer} |
	select-object FullName, LastWriteTime | export-csv -notypeinformation -delimiter '=' -path $updatedRecordsFile
}

function createACSVOfExistingFiles(){
	get-childitem -path $folderToCheck -recurse -exclude $excluded | where {!$_.PSIsContainer} |
	select-object FullName, LastWriteTime | export-csv -notypeinformation -delimiter '=' -path $defaultFile
}

function getDefaultFilesHashTable(){
	$default_file_content = Get-Content $defaultFile
	$default_file_content = $default_file_content -join [Environment]::NewLine
	
	return ConvertFrom-StringData($default_file_content)
}

function getUpdatedFilesHashTable(){
	$updated_file_content = Get-Content $updatedRecordsFile
	$updated_file_content = $updated_file_content -join [Environment]::NewLine
	
	return ConvertFrom-StringData($updated_file_content)
}

function makeUpdatedListAsDefaultList() {
	Copy-Item $updatedRecordsFile -Destination $defaultFile -Recurse
}

#script execution will start from here ..
if(Test-Path $defaultFile){
	
	createACSVOfNewFiles

	$default_configuration = getDefaultFilesHashTable
	
	$updated_configuration = getUpdatedFilesHashTable
	
	
	checkAndCreateNewFiles $default_configuration $updated_configuration
	
	checkAndRemoveMissingFiles $default_configuration $updated_configuration
	
	makeUpdatedListAsDefaultList

}else{
	createACSVOfExistingFiles
}