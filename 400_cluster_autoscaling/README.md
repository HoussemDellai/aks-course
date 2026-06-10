# AKS Cluster Autoscaler demystified

Disclaimer: This video is part of my Udemy course: https://www.udemy.com/course/learn-aks-network-security

## Create an AKS cluster with Cluster Autoscaler enabled

Lets deploy an AKS cluster with Cluster Autoscaler enabled with custom parameters:

* we are setting the `scan-interval` to 10s so that the cluster autoscaler checks for scaling opportunities every 10 seconds
* we are `setting the scale-down-delay-after-add` to 0s so that nodes can be scaled down immediately after new nodes are added
`scale-down-utilization-threshold` is Node utilization level, defined as sum of requested resources divided by capacity, in which a node can be considered for scale down.

>More details on the autoscaler parameters: https://learn.microsoft.com/en-us/azure/aks/cluster-autoscaler?tabs=azure-cli

```sh
az group create -n rg-aks-cluster -l swedencentral

az aks create -n aks-cluster -g rg-aks-cluster --network-plugin azure --network-plugin-mode overlay --network-dataplane cilium -k 1.34 --node-vm-size standard_d2ads_v6 --node-osdisk-type Ephemeral --node-osdisk-size 64 --enable-apiserver-vnet-integration --enable-cluster-autoscaler --min-count 1 --max-count 10 --cluster-autoscaler-profile scan-interval=10s,scale-down-delay-after-add=0m,scale-down-unneeded-time=1m,scale-down-unready-time=1m,scale-down-utilization-threshold=0.5,ignore-daemonsets-utilization=true

az aks get-credentials -n aks-cluster -g rg-aks-cluster --overwrite-existing

kubectl get nodes
```

## Deploy a sample application deployment

```sh
kubectl apply -f deployment.yaml
kubectl get deploy -w
```

## Trigger cluster autoscaling

To trigger cluster autoscaling, we will increase the number of replicas in the deployment to 20, each replicas is consuming 250m CPU.:      

```sh
kubectl scale deployment nginx-deployment --replicas=20
kubectl get deploy -w
```

Get nodes utilization (sum of requested CPU and Memory):

When using Linux/macOS:

```sh
# CPU requests per node (millicores)
kubectl get pods -A -o json \
| jq -r '
  .items[]
  | select(.spec.nodeName != null)
  | {node: .spec.nodeName, containers: .spec.containers}
  | .containers[]
  | select(.resources.requests.cpu != null)
  | {node: .node, cpu: .resources.requests.cpu}
' \
| jq -s '
  group_by(.node)
  | map({
      node: .[0].node,
      cpu_mcores: (
        map(.cpu)
        | map(
            if test("m$") then sub("m$"; "") | tonumber
            elif test("n$") then (sub("n$"; "") | tonumber) / 1000000
            elif test("u$") then (sub("u$"; "") | tonumber) / 1000
            else (sub("core$"; "") | tonumber) * 1000? // (tonumber * 1000)
            end
          )
        | add
      )
    })
' \
```

```sh
# Memory requests per node (bytes → human-readable)
kubectl get pods -A -o json \
| jq -r '
  .items[]
  | select(.spec.nodeName != null)
  | {node: .spec.nodeName, containers: .spec.containers}
  | .containers[]
  | select(.resources.requests.memory != null)
  | {node: .node, mem: .resources.requests.memory}
' \
| jq -s '
  # helper to convert K8s memory strings to bytes
  def to_bytes:
    if test("Ki$") then (sub("Ki$";"")|tonumber)*1024
    elif test("Mi$") then (sub("Mi$";"")|tonumber)*1024*1024
    elif test("Gi$") then (sub("Gi$";"")|tonumber)*1024*1024*1024
    elif test("Ti$") then (sub("Ti$";"")|tonumber)*1024*1024*1024*1024
    elif test("Pi$") then (sub("Pi$";"")|tonumber)*1024*1024*1024*1024*1024
    elif test("Ei$") then (sub("Ei$";"")|tonumber)*1024*1024*1024*1024*1024*1024
    elif test("K$")  then (sub("K$";"")|tonumber)*1000
    elif test("M$")  then (sub("M$";"")|tonumber)*1000*1000
    elif test("G$")  then (sub("G$";"")|tonumber)*1000*1000*1000
    elif test("T$")  then (sub("T$";"")|tonumber)*1000*1000*1000*1000
    elif test("P$")  then (sub("P$";"")|tonumber)*1000*1000*1000*1000*1000
    elif test("E$")  then (sub("E$";"")|tonumber)*1000*1000*1000*1000*1000*1000
    else tonumber
    end;

  def humanize:
    def fmt: if . < 1024 then . as $n | "\($n|floor) B"
             elif . < (1024^2) then (. / 1024) as $n | "\($n|round) KiB"
             elif . < (1024^3) then (. / (1024^2)) as $n | "\($n|round) MiB"
             elif . < (1024^4) then (. / (1024^3)) as $n | "\($n|round) GiB"
             else (. / (1024^4)) as $n | "\($n|round) TiB"
             end;

  group_by(.node)
  | map({
      node: .[0].node,
      mem_bytes: ( map(.mem | to_bytes) | add )
    })
' \
| jq -r '.[] | "\(.node)\t\(.mem_bytes) B"'
```

When using Powershell:

```powershell
# CPU requests per node (millicores)

$pods = kubectl get pods -A -o json | ConvertFrom-Json
$cpuByNode = @{}

function Convert-CpuToMilli {
    param([string]$cpu)
    if (-not $cpu) { return 0 }
    if ($cpu -match 'm$') { return [int]($cpu.TrimEnd('m')) }
    # nanos or micros → normalize to milli (rare in requests but safe)
    if ($cpu -match 'n$') { return [double]($cpu.TrimEnd('n')) / 1e6 }
    if ($cpu -match 'u$') { return [double]($cpu.TrimEnd('u')) / 1e3 }
    # plain cores, possibly decimal
    return [double]$cpu * 1000
}

foreach ($p in $pods.items) {
    if (-not $p.spec.nodeName) { continue }
    $node = $p.spec.nodeName
    foreach ($c in $p.spec.containers) {
        $req = $c.resources.requests
        if ($req -and $req.cpu) {
            $mcpu = Convert-CpuToMilli $req.cpu
            if (-not $cpuByNode.ContainsKey($node)) { $cpuByNode[$node] = 0 }
            $cpuByNode[$node] += $mcpu
        }
    }
}

$cpuByNode.GetEnumerator() | Sort-Object Name |
    ForEach-Object { "{0}`t{1} mCPU" -f $_.Key, [math]::Round($_.Value,2) }

# aks-nodepool1-49969197-vmss000000       1530 mCPU
# aks-nodepool1-49969197-vmss000001       1570 mCPU
# aks-nodepool1-49969197-vmss000003       1510 mCPU
# aks-nodepool1-49969197-vmss000004       1410 mCPU
# aks-nodepool1-49969197-vmss000005       1570 mCPU
# aks-nodepool1-49969197-vmss000006       1410 mCPU
# aks-nodepool1-49969197-vmss000007       1570 mCPU
# aks-nodepool1-49969197-vmss000008       1410 mCPU
# aks-nodepool1-49969197-vmss000009       1410 mCPU
# aks-nodepool1-49969197-vmss00000a       1410 mCPU
```

```powershell
# Memory requests per node (bytes → human-readable)
$pods = kubectl get pods -A -o json | ConvertFrom-Json
$memByNode = @{}

function Convert-MemoryToBytes {
    param([string]$mem)
    if (-not $mem) { return 0 }
    # Binary suffixes
    if ($mem -match 'Ki$') { return [double]$mem.TrimEnd('K','i') * 1KB }
    if ($mem -match 'Mi$') { return [double]$mem.TrimEnd('M','i') * 1MB }
    if ($mem -match 'Gi$') { return [double]$mem.TrimEnd('G','i') * 1GB }
    if ($mem -match 'Ti$') { return [double]$mem.TrimEnd('T','i') * 1TB }
    if ($mem -match 'Pi$') { return [double]$mem.TrimEnd('P','i') * 1TB * 1024 } # rough
    if ($mem -match 'Ei$') { return [double]$mem.TrimEnd('E','i') * 1TB * 1024 * 1024 }
    # Decimal suffixes
    if ($mem -match 'K$')  { return [double]$mem.TrimEnd('K')  * 1000 }
    if ($mem -match 'M$')  { return [double]$mem.TrimEnd('M')  * 1e6 }
    if ($mem -match 'G$')  { return [double]$mem.TrimEnd('G')  * 1e9 }
    if ($mem -match 'T$')  { return [double]$mem.TrimEnd('T')  * 1e12 }
    if ($mem -match 'P$')  { return [double]$mem.TrimEnd('P')  * 1e15 }
    if ($mem -match 'E$')  { return [double]$mem.TrimEnd('E')  * 1e18 }
    # plain bytes
    return [double]$mem
}

function Humanize-Bytes {
    param([double]$bytes)
    $units = "B","KiB","MiB","GiB","TiB","PiB","EiB"
    $i = 0
    while ($bytes -ge 1024 -and $i -lt $units.Length-1) { $bytes /= 1024; $i++ }
    "{0:n2} {1}" -f $bytes, $units[$i]
}

foreach ($p in $pods.items) {
    if (-not $p.spec.nodeName) { continue }
    $node = $p.spec.nodeName
    foreach ($c in $p.spec.containers) {
        $req = $c.resources.requests
        if ($req -and $req.memory) {
            $bytes = Convert-MemoryToBytes $req.memory
            if (-not $memByNode.ContainsKey($node)) { $memByNode[$node] = 0 }
            $memByNode[$node] += $bytes
        }
    }
}

$memByNode.GetEnumerator() | Sort-Object Name |
    ForEach-Object {
        $human = Humanize-Bytes $_.Value
        "{0}`t{1} bytes ({2})" -f $_.Key, [math]::Round($_.Value), $human
    }

# aks-nodepool1-49969197-vmss000000       2740977664 bytes (2.55 GiB)
# aks-nodepool1-49969197-vmss000001       1688207360 bytes (1.57 GiB)
# aks-nodepool1-49969197-vmss000003       2812280832 bytes (2.62 GiB)
# aks-nodepool1-49969197-vmss000004       2812280832 bytes (2.62 GiB)
# aks-nodepool1-49969197-vmss000005       1751121920 bytes (1.63 GiB)
# aks-nodepool1-49969197-vmss000007       499122176 bytes (476.00 MiB)
# aks-nodepool1-49969197-vmss000008       2646605824 bytes (2.46 GiB)
```