# Azure VMSS Deployment Automation Script

# 1. Create resource group
$location = "westeurope"
$rgName = "rg-my-vmss"
New-AzResourceGroup -Name $rgName -Location $location

# 2. Create virtual network and subnet
$vnet = New-AzVirtualNetwork -ResourceGroupName $rgName -Name "vmss-vnet" -Location $location `
    -AddressPrefix "10.0.0.0/16" `
    -Subnet @(New-AzVirtualNetworkSubnetConfig -Name "vmss-subnet" -AddressPrefix "10.0.1.0/24")

# 3. Create Network Security Group (NSG) and rule for HTTP
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $rgName -Location $location -Name "vmss-nsg"
$nsgRule = New-AzNetworkSecurityRuleConfig -Name "AllowHTTP" -Protocol "Tcp" -Direction "Inbound" `
    -Priority 100 -SourceAddressPrefix "*" -SourcePortRange "*" `
    -DestinationAddressPrefix "*" -DestinationPortRange 80 -Access "Allow"
$nsg.SecurityRules += $nsgRule
Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsg

# 4. Create Public IP and Load Balancer
$publicIp = New-AzPublicIpAddress -Name "vmss-ip" -ResourceGroupName $rgName `
    -Location $location -AllocationMethod Static -Sku Standard

$frontend = New-AzLoadBalancerFrontendIpConfig -Name "frontend" -PublicIpAddress $publicIp

$backend = New-AzLoadBalancerBackendAddressPoolConfig -Name "backend"

$lbrule = New-AzLoadBalancerRuleConfig -Name "http-rule" -Protocol Tcp -FrontendPort 80 -BackendPort 80 `
    -FrontendIpConfiguration $frontend -BackendAddressPool $backend -Probe $null

$lb = New-AzLoadBalancer -ResourceGroupName $rgName -Name "vmss-lb" -Location $location `
    -Sku "Standard" -FrontendIpConfiguration $frontend -BackendAddressPool $backend -LoadBalancingRule $lbrule

# 5. Configure VM Scale Set (VMSS)
$ipConfig = New-AzVmssIpConfig -Name "ipconfig" `
    -LoadBalancerBackendAddressPoolsId $lb.BackendAddressPools[0].Id `
    -SubnetId $vnet.Subnets[0].Id

$vmProfile = New-AzVmssConfig -Location $location -SkuCapacity 2 -SkuName "Standard_DS1_v2" `
    -UpgradePolicyMode "Automatic"

Set-AzVmssStorageProfile $vmProfile -ImageReferencePublisher "Canonical" -ImageReferenceOffer "UbuntuServer" `
    -ImageReferenceSku "18.04-LTS" -ImageReferenceVersion "latest" `
    -OsDiskCreateOption "FromImage" -ManagedDiskStorageAccountType "Standard_LRS"

Set-AzVmssOSProfile $vmProfile -ComputerNamePrefix "vmss" -AdminUsername "azureuser" -AdminPassword "SecurePassword123!"

Add-AzVmssNetworkInterfaceConfiguration -VirtualMachineScaleSet $vmProfile `
    -Name "vmss-nic" -Primary $true -IPConfiguration $ipConfig

# 6. Create the VM Scale Set
New-AzVmss -ResourceGroupName $rgName -Name "myVMSS" -VirtualMachineScaleSet $vmProfile

# 7. (Optional) Configure autoscaling (replace <subscriptionID> with your subscription ID)
# Add-AzAutoscaleSetting -ResourceGroupName $rgName -TargetResourceId "/subscriptions/<subscriptionID>/resourceGroups/$rgName/providers/Microsoft.Compute/virtualMachineScaleSets/myVMSS" `
#     -Name "vmss-autoscale" -Location $location -MinCount 2 -MaxCount 5 -DefaultCount 2 `
#     -ScaleOutRuleMetricName "Percentage CPU" -ScaleOutThreshold 70 -ScaleOutCooldown "PT5M" -ScaleOutChangeCount 1 `
#     -ScaleInRuleMetricName "Percentage CPU" -ScaleInThreshold 30 -ScaleInCooldown "PT5M" -ScaleInChangeCount 1

# 8. Check deployment result
Get-AzVmss -ResourceGroupName $rgName -VMScaleSetName "myVMSS"
