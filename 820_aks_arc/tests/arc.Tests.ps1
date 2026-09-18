$ErrorActionPreference = 'Stop'
$script:commands = [System.Collections.Generic.List[object]]::new()
$script:failure = ''
$script:arcExists = $true
$global:ArcDemoTestState = @{ Commands = $script:commands; Failure = ''; ArcExists = $true }

function az {
    $global:ArcDemoTestState.Commands.Add(@('az') + $args)
    $global:LASTEXITCODE = 0
    $operation = "$($args[0]) $($args[1])"
    if ($global:ArcDemoTestState.Failure -eq $operation) {
        $global:LASTEXITCODE = 1
    }
    elseif ($operation -eq 'connectedk8s list') {
        if ($global:ArcDemoTestState.ArcExists) { '[{"name":"arc-test-dev"}]' } else { '[]' }
    }
}

function kubectl {
    $global:ArcDemoTestState.Commands.Add(@('kubectl') + $args)
    $global:LASTEXITCODE = $(if ($global:ArcDemoTestState.Failure -eq 'kubectl') { 1 } else { 0 })
}

function Assert-True {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
}

$parameters = @{
    SubscriptionId = '00000000-0000-0000-0000-000000000000'
    ResourceGroup  = 'rg-test-dev'
    AksName        = 'aks-test-dev'
    ArcName        = 'arc-test-dev'
    Location       = 'swedencentral'
    Environment    = 'dev'
}
$scriptPath = Join-Path $PSScriptRoot '../scripts/arc.ps1'
$originalKubeconfig = $env:KUBECONFIG
$originalExitCode = $global:LASTEXITCODE

try {
    foreach ($scenario in @('Connect', 'Disconnect', 'Absent', 'CredentialFailure', 'ConnectFailure', 'DeleteFailure', 'AgentFailure', 'ListFailure')) {
        $script:commands.Clear()
        $script:arcExists = $scenario -ne 'Absent'
        $script:failure = switch ($scenario) {
            'CredentialFailure' { 'aks get-credentials' }
            'ConnectFailure' { 'connectedk8s connect' }
            'DeleteFailure' { 'connectedk8s delete' }
            'AgentFailure' { 'kubectl' }
            'ListFailure' { 'connectedk8s list' }
            default { '' }
        }
        $global:ArcDemoTestState.Failure = $script:failure
        $global:ArcDemoTestState.ArcExists = $script:arcExists
        $action = if ($scenario -in @('Disconnect', 'Absent', 'DeleteFailure', 'ListFailure')) { 'Disconnect' } else { 'Connect' }
        $failed = $false
        try {
            & $scriptPath -Action $action @parameters
        }
        catch {
            if ($script:failure -eq '') { throw }
            $failed = $true
        }
        Assert-True ($failed -eq ($script:failure -ne '')) "$scenario did not propagate the expected result."

        $credentials = @($script:commands | Where-Object { $_[0] -eq 'az' -and $_[1] -eq 'aks' })
        if ($scenario -in @('Absent', 'ListFailure')) {
            Assert-True ($script:commands.Count -eq 1) "$scenario must stop after listing Arc resources."
        }
        else {
            Assert-True ($credentials.Count -eq 1) "$scenario must fetch credentials exactly once."
            $credentialCommand = $credentials[0]
            $configPath = $credentialCommand[[array]::IndexOf($credentialCommand, '--file') + 1]
            Assert-True (-not (Test-Path -LiteralPath $configPath)) "$scenario leaked a temporary kubeconfig."
            Assert-True ($credentialCommand -contains '--admin') "$scenario must request cluster-admin credentials for onboarding."

            foreach ($command in $script:commands | Where-Object { $_[2] -in @('connect', 'delete') }) {
                $arcConfig = $command[[array]::IndexOf($command, '--kube-config') + 1]
                Assert-True ($arcConfig -eq $configPath) "$scenario used the wrong kubeconfig for Arc."
            }
        }

        foreach ($command in $script:commands | Where-Object { $_[0] -eq 'az' }) {
            Assert-True ($command -contains $parameters.SubscriptionId) "$scenario omitted the subscription."
            Assert-True ($command -contains $parameters.ResourceGroup) "$scenario omitted the resource group."
        }
        if ($scenario -eq 'Connect') {
            Assert-True ($script:commands.Count -eq 3) 'Connect must fetch credentials, connect Arc and wait for agents.'
            Assert-True ($script:commands[1] -contains '--distribution') 'Connect must specify the Kubernetes distribution.'
            Assert-True ($script:commands[2][0] -eq 'kubectl') 'Connect must check agent availability.'
        }
        if ($scenario -eq 'Disconnect') {
            Assert-True ($script:commands.Count -eq 3) 'Disconnect must list Arc resources, fetch credentials and delete Arc.'
            Assert-True ($script:commands[2][2] -eq 'delete') 'Disconnect must remove the Arc resource and agents.'
        }
        Assert-True ($env:KUBECONFIG -eq $originalKubeconfig) "$scenario changed the caller's KUBECONFIG."
        Write-Host "PASS: $scenario"
    }
}
finally {
    $global:LASTEXITCODE = $originalExitCode
    Remove-Variable -Name ArcDemoTestState -Scope Global
}