# 🚀 Azure VMSS Deployment Automation Script

This PowerShell script automates the creation of an Azure Virtual Machine Scale Set (VMSS) with:

- Resource Group
- Virtual Network and Subnet
- Network Security Group with HTTP rule
- Public IP and Load Balancer
- VM Scale Set with Ubuntu 18.04
- (Optional) Auto-scaling configuration

---

## 📂 Requirements

- Azure PowerShell module (`Az`)
- Logged in to your Azure account (`Connect-AzAccount`)
- Sufficient permissions to create resources

---

## ⚙️ Usage

Run the script in PowerShell:

```powershell
.\deploy-vmss.ps1
