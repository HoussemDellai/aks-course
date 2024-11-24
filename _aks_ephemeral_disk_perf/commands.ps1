$AKS_NAME = "aks-cluster"
$AKS_RG = "rg-aks-cluster-ephemeral-disk"

az group create --name $AKS_RG --location swedencentral

# E16d-v5
az aks create -g $AKS_RG -n $AKS_NAME --network-plugin azure --network-plugin-mode overlay -k 1.30.5 --node-vm-size Standard_E16ds_v5 --node-osdisk-type Ephemeral

az aks get-credentials -g $AKS_RG -n $AKS_NAME --overwrite-existing


$ kubectl top nodes
# NAME                                CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
# aks-nodepool1-41660317-vmss000000   84m          0%     952Mi           0%
# aks-nodepool1-41660317-vmss000001   35m          0%     747Mi           0%
# aks-nodepool1-41660317-vmss000002   92m          0%     965Mi           0%

kubectl debug node/aks-nodepool1-41660317-vmss000000 -it --image=mcr.microsoft.com/cbl-mariner/busybox:2.0
# Creating debugging pod node-debugger-aks-nodepool1-41660317-vmss000000-wv79g with container debugger on node aks-nodepool1-41660317-vmss000000.
# If you don't see a command prompt, try pressing enter.
# / # chroot /host
# root@aks-nodepool1-41660317-vmss000000:/# apt-get install fio
# root@aks-nodepool1-41660317-vmss000000:/# fio --name=8krandomreads --rw=randread --direct=1 --ioengine=libaio --bs=8k --numjobs=4 --iodepth=128 --size=4G --runtime=600 --group_reporting
# 8krandomreads: (g=0): rw=randread, bs=(R) 8192B-8192B, (W) 8192B-8192B, (T) 8192B-8192B, ioengine=libaio, iodepth=128
# ...
# fio-3.28
# Starting 4 processes
# Jobs: 4 (f=4): [r(4)][96.4%][r=597MiB/s][r=76.4k IOPS][eta 00m:01s]
# 8krandomreads: (groupid=0, jobs=4): err= 0: pid=50301: Wed Nov 20 13:28:51 2024
#   read: IOPS=75.5k, BW=589MiB/s (618MB/s)(16.0GiB/27794msec)
#     slat (nsec): min=1141, max=26996k, avg=28895.00, stdev=267174.65
#     clat (usec): min=84, max=65541, avg=6728.61, stdev=5139.14
#      lat (usec): min=90, max=65543, avg=6757.60, stdev=5152.03
#     clat percentiles (usec):
#      |  1.00th=[  996],  5.00th=[ 1516], 10.00th=[ 1795], 20.00th=[ 2376],
#      | 30.00th=[ 3228], 40.00th=[ 4178], 50.00th=[ 5342], 60.00th=[ 6718],
#      | 70.00th=[ 8455], 80.00th=[10421], 90.00th=[13304], 95.00th=[15926],
#      | 99.00th=[25822], 99.50th=[28967], 99.90th=[34866], 99.95th=[36963],
#      | 99.99th=[47449]
#    bw (  KiB/s): min=531072, max=675648, per=100.00%, avg=603864.70, stdev=7041.15, samples=219
#    iops        : min=66384, max=84456, avg=75483.09, stdev=880.14, samples=219
#   lat (usec)   : 100=0.01%, 250=0.05%, 500=0.16%, 750=0.26%, 1000=0.55%
#   lat (msec)   : 2=13.08%, 4=24.07%, 10=39.68%, 20=19.90%, 50=2.24%
#   lat (msec)   : 100=0.01%
#   cpu          : usr=1.63%, sys=6.98%, ctx=1367530, majf=0, minf=1078
#   IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=0.1%, >=64=100.0%
#      submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
#      complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.1%
#      issued rwts: total=2097152,0,0,0 short=0,0,0,0 dropped=0,0,0,0
#      latency   : target=0, window=0, percentile=100.00%, depth=128

# Run status group 0 (all jobs):
#    READ: bw=589MiB/s (618MB/s), 589MiB/s-589MiB/s (618MB/s-618MB/s), io=16.0GiB (17.2GB), run=27794-27794msec

# Disk stats (read/write):
#   sda: ios=2082524/20, merge=1519/56, ticks=11667708/23, in_queue=11667737, util=99.70%
# root@aks-nodepool1-41660317-vmss000000:/#

# root@aks-nodepool1-41660317-vmss000000:/# fio --name=8krandomwrites --rw=randwrite --direct=1 --ioengine=libaio --bs=8k --numjobs=4 --iodepth=128 --size=4G --runtime=600 --group_reporting
# 8krandomwrites: (g=0): rw=randwrite, bs=(R) 8192B-8192B, (W) 8192B-8192B, (T) 8192B-8192B, ioengine=libaio, iodepth=128
# ...
# fio-3.28
# Starting 4 processes
# Jobs: 1 (f=1): [w(1),_(3)][100.0%][w=604MiB/s][w=77.3k IOPS][eta 00m:00s]
# 8krandomwrites: (groupid=0, jobs=4): err= 0: pid=53777: Wed Nov 20 13:31:51 2024
#   write: IOPS=75.0k, BW=586MiB/s (615MB/s)(16.0GiB/27954msec); 0 zone resets
#     slat (nsec): min=1237, max=20857k, avg=18445.90, stdev=202917.50
#     clat (usec): min=61, max=67647, avg=6761.09, stdev=5926.16
#      lat (usec): min=64, max=67655, avg=6779.62, stdev=5939.86
#     clat percentiles (usec):
#      |  1.00th=[ 1172],  5.00th=[ 1762], 10.00th=[ 2073], 20.00th=[ 2606],
#      | 30.00th=[ 3195], 40.00th=[ 3818], 50.00th=[ 4621], 60.00th=[ 5669],
#      | 70.00th=[ 7308], 80.00th=[ 9896], 90.00th=[14746], 95.00th=[19530],
#      | 99.00th=[28705], 99.50th=[32637], 99.90th=[41157], 99.95th=[44827],
#      | 99.99th=[50594]
#    bw (  KiB/s): min=503056, max=694704, per=100.00%, avg=600362.76, stdev=10766.57, samples=220
#    iops        : min=62882, max=86838, avg=75045.31, stdev=1345.81, samples=220
#   lat (usec)   : 100=0.01%, 250=0.03%, 500=0.09%, 750=0.20%, 1000=0.34%
#   lat (msec)   : 2=8.04%, 4=34.09%, 10=37.55%, 20=15.10%, 50=4.56%
#   lat (msec)   : 100=0.01%
#   cpu          : usr=1.60%, sys=6.07%, ctx=847018, majf=1, minf=53
#   IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=0.1%, >=64=100.0%
#      submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
#      complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.1%
#      issued rwts: total=0,2097152,0,0 short=0,0,0,0 dropped=0,0,0,0
#      latency   : target=0, window=0, percentile=100.00%, depth=128

# Run status group 0 (all jobs):
#   WRITE: bw=586MiB/s (615MB/s), 586MiB/s-586MiB/s (615MB/s-615MB/s), io=16.0GiB (17.2GB), run=27954-27954msec

# Disk stats (read/write):
#   sda: ios=0/2089353, merge=0/2689, ticks=0/11925465, in_queue=11925471, util=99.72%
# root@aks-nodepool1-41660317-vmss000000:/#




kubectl apply -f https://raw.githubusercontent.com/yasker/kbench/main/deploy/fio.yaml

kubectl logs -l kbench=fio -f
# TEST_FILE: /volume/test
# TEST_OUTPUT_PREFIX: test_device
# TEST_SIZE: 30G
# Benchmarking iops.fio into test_device-iops.json
# Benchmarking bandwidth.fio into test_device-bandwidth.json
# Benchmarking latency.fio into test_device-latency.json

# =========================
# FIO Benchmark Summary
# For: test_device
# CPU Idleness Profiling: disabled
# Size: 30G
# Quick Mode: disabled
# =========================
# IOPS (Read/Write)
#         Random:             76,440 / 612
#     Sequential:             76,442 / 610

# Bandwidth in KiB/sec (Read/Write)
#         Random:       1,593,679 / 78,380
#     Sequential:       1,592,844 / 78,262


# Latency in ns (Read/Write)
#         Random:      108,203 / 1,634,187
#     Sequential:       44,322 / 1,638,503