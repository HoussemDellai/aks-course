[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Connect', 'Disconnect')]
    [string] $Action,
    [string] $SubscriptionId = $env:ARC_SUBSCRIPTION_ID,
    [string] $ResourceGroup = $env:ARC_RESOURCE_GROUP,
    [string] $AksName = $env:ARC_AKS_NAME,
    [string] $ArcName = $env:ARC_NAME,
    [string] $Location = $env:ARC_LOCATION,
    [string] $Environment = $env:ARC_ENVIRONMENT
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

foreach ($value in @($SubscriptionId, $ResourceGroup, $AksName, $ArcName, $Location, $Environment)) {
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw 'SubscriptionId, ResourceGroup, AksName, ArcName, Location and Environment are required.'
    }
}

Get-Command az -ErrorAction Stop | Out-Null
Get-Command kubectl -ErrorAction Stop | Out-Null

function Invoke-AzureCli {
    param([string[]] $Arguments)

    & az @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI failed (exit $LASTEXITCODE): az $($Arguments[0]) $($Arguments[1])"
    }
}

$scope = @('--subscription', $SubscriptionId, '--resource-group', $ResourceGroup)

if ($Action -eq 'Disconnect') {
    $clusters = Invoke-AzureCli -Arguments (@('connectedk8s', 'list') + $scope + @('--output', 'json', '--only-show-errors'))
    $exists = @($clusters | ConvertFrom-Json | Where-Object { $_.name -eq $ArcName }).Count -gt 0
    if (-not $exists) {
        Write-Host "Arc resource $ArcName is already absent."
        return
    }
}

$kubeconfig = [System.IO.Path]::GetTempFileName()
try {
    Invoke-AzureCli -Arguments (@('aks', 'get-credentials') + $scope + @(
        '--name', $AksName, '--admin', '--file', $kubeconfig,
        '--overwrite-existing', '--output', 'none', '--only-show-errors'
    ))

    $arcArguments = $scope + @('--name', $ArcName, '--kube-config', $kubeconfig, '--only-show-errors', '--output', 'none')
    if ($Action -eq 'Connect') {
        Write-Host "Connecting $AksName to Azure Arc as $ArcName."
        Invoke-AzureCli -Arguments (@('connectedk8s', 'connect') + $arcArguments + @(
            '--location', $Location, '--distribution', 'aks', '--infrastructure', 'azure',
            '--tags', "environment=$Environment", 'purpose=aks-arc-demo', 'managed_by=terraform',
            '--onboarding-timeout', '1200', '--yes'
        ))

        & kubectl --kubeconfig $kubeconfig --namespace azure-arc wait deployment --all --for=condition=Available --timeout=300s
        if ($LASTEXITCODE -ne 0) {
            throw "Arc agent deployments did not become available on $AksName."
        }
    }
    else {
        Write-Host "Disconnecting $ArcName before deleting $AksName."
        Invoke-AzureCli -Arguments (@('connectedk8s', 'delete') + $arcArguments + @('--yes'))
    }
}
finally {
    Remove-Item -LiteralPath $kubeconfig -Force -ErrorAction SilentlyContinue
}