$env:Path += ";C:\opscode\chefdk\embedded\bin\"
$chefdk_ver = ''
$ruby_ver = ''

function DownloadFile($url, $targetFile){
    try{
        $output = $targetFile
        $start_time = Get-Date

        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($url, $output)
    }catch{
        Write-Host "Unable to download from $url"
        Remove-Item -Path $targetFile -Force
        exit
    }
}

function install_chefDK {
    DownloadFile "https://packages.chef.io/files/stable/chefdk/3.8.14/windows/2012r2/chefdk-3.8.14-1-x64.msi" "$env:TEMP/chefdk.msi"
    $DataStamp = get-date -Format yyyyMMddTHHmmss
    $file = 'chefdk.msi'
    $logFile = '{0}-{1}.log' -f 'chef-dk',$DataStamp
    $MSIArguments = @(
        "/i"
        ('"{0}"' -f $file)
        "/qn"
        "/norestart"
        "/L*v"
        $logFile
    )
    Set-Location -Path $env:TEMP
    Start-Process msiexec.exe -Wait -ArgumentList $MSIArguments
    if(Get-Command "terraform.exe" -ErrorAction SilentlyContinue){
        Write-Host "Chef-DK installed successfully."
    }
    else{
        Write-Host "Failed to install Chef-DK"
    }
}

function install_gems {
    if(Get-Command "terraform.exe" -ErrorAction SilentlyContinue){
        Write-Host "Found Ruby, installing the required gems"
        gem install kitchen-terraform --no-rdoc --no-ri --no-http-proxy
        gem install awspec --no-rdoc --no-ri --no-http-proxy
        gem install kitchen-verifier-awspec --no-rdoc --no-ri --no-http-proxy
        gem install rhcl --no-http-proxy --no-rdoc --no-ri
    }
    else {
        Write-Host 'gem executible not found exiting..'
        exit
    }
}

function updateEnvVariable{
    if(([Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)).contains('chefdk\embedded')){
        Write-Host 'ENV Variables already set correctly'
    }
    else{
        Write-Host "Adding ruby bin to the path"
        [Environment]::SetEnvironmentVariable(
            "Path",
            [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";C:\opscode\chefdk\embedded\bin\",
            [EnvironmentVariableTarget]::Machine
        )
    }
}

function installTerraform{
    DownloadFile "https://releases.hashicorp.com/terraform/0.11.13/terraform_0.11.13_windows_amd64.zip" "$env:TEMP/terraform.zip"
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory("$env:TEMP/terraform.zip", 'C:\opscode\chefdk\embedded\bin\')
}

function installTerraparser{
    Write-Host 'Downloading the ChefDK installer'
    DownloadFile "https://raw.githubusercontent.com/rajshekhar17/terra_erb_parser/master/main.rb" 'C:\opscode\chefdk\embedded\bin\Terraparser.rb'
}

if(!(Test-Path -type leaf -path 'C:\opscode\chefdk\chef')){
    Write-Host 'Installing Chef-DK'
    install_chefDK
}

updateEnvVariable

install_gems

if(Get-Command "terraform.exe" -ErrorAction SilentlyContinue){
    Write-Host "Terraform in already installed"
}
else{
    Write-Host 'Downloading and installing Terraform'
    installTerraform
}

Write-Host 'Downloading Terraparser'
installTerraparser