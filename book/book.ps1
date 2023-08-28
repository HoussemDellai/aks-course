pandoc -t docx ..\01_create_aca_cli\Readme.md ..\02_create_frontend_backend_cli\Readme.md ..\03_create_aca_terraform\Readme.md ..\04_create_aca_apps_terraform\Readme.md ..\05_create_aca_bicep\Readme.md ..\06_create_aca_apps_bicep\Readme.md ..\07_aca_workshop\Readme.md ..\08_aca_workshop_mi\Readme.md ..\09_aca_github_actions\Readme.md ..\10_aca_azuredevops\Readme.md -o book.docx

pandoc -V geometry:a4paper, margin=2cm ..\01_create_aca_cli\Readme.md ..\02_create_frontend_backend_cli\Readme.md ..\03_create_aca_terraform\Readme.md ..\04_create_aca_apps_terraform\Readme.md ..\05_create_aca_bicep\Readme.md ..\06_create_aca_apps_bicep\Readme.md ..\07_aca_workshop\Readme.md ..\08_aca_workshop_mi\Readme.md ..\09_aca_github_actions\Readme.md ..\10_aca_azuredevops\Readme.md -s -o book.pdf

pandoc -s --toc -o book.pdf -V geometry:a4paper, margin=2cm ..\01_create_aca_cli\Readme.md ..\02_create_frontend_backend_cli\Readme.md ..\03_create_aca_terraform\Readme.md ..\04_create_aca_apps_terraform\Readme.md ..\05_create_aca_bicep\Readme.md ..\06_create_aca_apps_bicep\Readme.md ..\07_aca_workshop\Readme.md ..\08_aca_workshop_mi\Readme.md ..\09_aca_github_actions\Readme.md ..\10_aca_azuredevops\Readme.md 

# list Readme.md files in different folders

$ReadmeFiles = $(Get-ChildItem –Path ../ -Recurse -Include Readme.md)

$ReadmeFiles | Select FullName

$ReadmeFiles | Select DirectoryName



$modified = $ReadmeFile.Replace('<img src="', '![](').Replace('">', ')')

Set-Content -Path .\Readme.md -Value $modified

Rename-Item -Path .\images\app_gateway.png -NewName 66_appgw_for_containers__app_gateway.png

ForEach ($folder in $(Get-ChildItem –Path ../ -Recurse -Include Readme.md)) {
    echo "Processing $folder.Name ..."

    $ReadmeFile = $folder.FullName
    $modified = $ReadmeFile.Replace('<img src="', '![](').Replace('">', ')')
    Set-Content -Path $ReadmeFile -Value $modified
}

ForEach ($image in $(Get-ChildItem –Path .\images\ -Recurse -Include *.png)) {
    $imageNewName = $image.Name
    Set-Content -Path $image.FullName -Value $modified
}





# replaces <img src=" ... "/> with ![]( ... ) in all Readme files
ForEach ($readmeFile in $(Get-ChildItem –Path ../ -Recurse -Include Readme.md)) {
    
    echo "Processing $readmeFile ..."

    $content = $(Get-Content -Path $readmeFile)

    # $modified = $content.Replace('![](', '<img src="').Replace(')', '"/>')
    $modified = $content.Replace('<img src="', '![](').Replace('">', ')').Replace('"/>', ')')
    
    echo $modified

    Set-Content -Path $readmeFile -Value $modified
}

# rename images in /images folders and in Readme.md files
ForEach ($readmeFile in $(Get-ChildItem –Path ../ -Recurse -Include Readme.md)) {
    
    $imgFolderFullName = $readmeFile.Directory.FullName + "\images"

    echo "Processing $imgFolderFullName ..."

    ForEach ($img in $(Get-ChildItem –Path $imgFolderFullName -Recurse -Include *.png)) {
        
        echo "Processing $img ..."

        If ($img.Name.Contains("__")) {
            echo "Skipping $img ..."
            continue
        }
        
        $newName = $readmeFile.Directory.Name + "__" + $img.Name
        
        echo "Renaming $img to $newName ..."
        
        Rename-Item -Path $img.FullName -NewName $newName

        $content = $(Get-Content -Path $readmeFile)

        $modified = $content.Replace($img.Name, $newName)

        Set-Content -Path $readmeFile -Value $modified
    }
}

# copy all images from all /images folders to a single /images folder

ForEach ($readmeFile in $(Get-ChildItem –Path ../ -Recurse -Include Readme.md)) {
    
    $imgFolderFullName = $readmeFile.Directory.FullName + "\images"

    echo "Processing $imgFolderFullName ..."

    Copy-Item -Path $imgFolderFullName -Destination . -Recurse
}

# generate chapters
ForEach ($readmeFile in $(Get-ChildItem –Path ../ -Recurse -Include Readme.md)) {

    $bookName = $readmeFile.Directory.Name + ".docx"

    echo "Processing $readmeFile ..." 

    echo "Generating $bookName ..." 

    pandoc -s --toc -o chapters\$bookName -V geometry:a4paper,margin=2cm $readmeFile
}


# get all folders containing Readme.md files
$readmeFiles = $(Get-ChildItem –Path ../ -Recurse -Include Readme.md).FullName

# generate book
pandoc -s --toc -o book.docx -V geometry:a4paper,margin=2cm $readmeFiles 




# close word process
Stop-Process -processname "WINWORD"

# rmove docx file
sleep 1
rm chapter.docx

# --highlight-style
pandoc -s --toc -o chapter.docx -V geometry:a4paper,margin=1cm Readme.md --highlight-style breezeDark

# start word process to open docx file
Start-Process 'C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE' .\chapter.docx


# print the theme
pandoc --print-highlight-style breezedark > breezedark.theme 


pandoc -s --toc -o chapter.docx -V geometry:a4paper,margin=1cm Readme.md --highlight-style ..\book\github-light.theme


pandoc -s --toc -o chapter.docx -V geometry:a4paper,margin=1cm Readme.md --syntax-definition bash.xml


# cspell

choco install nodejs.install
# restart terminal
npm install -g cspell


cspell --words-only --unique --config cspell.config.yaml .\07_calico_network_policy\README.md | sort --ignore-case >> project-words.txt
# cspell --words-only --unique "**/*.md" | sort --ignore-case > .\.spell_check\project-words.txt

cspell --no-progress --show-suggestions --show-context "**/*.md"

