!/bin/bash
export MSYS_NO_PATHCONV=1
west_us_location='westus' 
east_us_location='eastus' 
env='test'
resourceGroup='rs_vnet_test_topology_hub_sub_'$env
sshkey_vm1_name='vm1-hub1-key'
sshkey_vm2_name='vm1-static-spoke1-key'
sshkey_vm3_name='vm1-static-spoke2-key'
sshkey_vm4_name='vm1-dynamic-spoke1-key'
sshkey_vm5_name='vm1-dynamic-spoke2-key'
sshkey_vm6_name='vm1-hub2-keyy'


az group create --name ${resourceGroup} --location $west_us_location --query id --output tsv



existing_files="$v(ls ~/.ssh)"
az sshkey create --name $sshkey_vm1_name --resource-group $resourceGroup 
new_files=$(ls ~/.ssh | grep -v -f <(echo "$existing_files"))
key_file1_name=$(echo "$new_files" | grep -v '\.pub$')

existing_files=$(ls ~/.ssh)
az sshkey create --name $sshkey_vm2_name --resource-group $resourceGroup
new_files=$(ls ~/.ssh | grep -v -f <(echo "$existing_files"))
key_file2_name=$(echo "$new_files" | grep -v '\.pub$')

existing_files=$(ls ~/.ssh)
az sshkey create --name $sshkey_vm3_name --resource-group $resourceGroup
new_files=$(ls ~/.ssh | grep -v -f <(echo "$existing_files"))
key_file3_name=$(echo "$new_files" | grep -v '\.pub$')

existing_files=$(ls ~/.ssh)
az sshkey create --name $sshkey_vm4_name --resource-group $resourceGroup
new_files=$(ls ~/.ssh | grep -v -f <(echo "$existing_files"))
key_file4_name=$(echo "$new_files" | grep -v '\.pub$')

existing_files=$(ls ~/.ssh)
az sshkey create --name $sshkey_vm5_name --resource-group $resourceGroup
new_files=$(ls ~/.ssh | grep -v -f <(echo "$existing_files"))
key_file5_name=$(echo "$new_files" | grep -v '\.pub$')
existing_files=$(ls ~/.ssh)

existing_files=$(ls ~/.ssh)
az sshkey create --name $sshkey_vm6_name --resource-group $resourceGroup
new_files=$(ls ~/.ssh | grep -v -f <(echo "$existing_files"))
key_file6_name=$(echo "$new_files" | grep -v '\.pub$')

echo $key_file1_name  $key_file2_name $key_file3_name $key_file4_name $key_file5_name $key_file6_name


az deployment group create \
  --resource-group ${resourceGroup} \
  --name create_hub_spoke_topology \
  --template-file ./hub_spoke/multi_region_azure_firewall_routing/main.bicep \
  --parameters \
    hub1VnetLocation=$west_us_location \
    hub2VnetLocation=$east_us_location \
    sshHub1Vm1KeyName=$sshkey_vm1_name \
    sshStaticSpoke1Vm1KeyName=$sshkey_vm2_name \
    sshStaticSpoke2Vm1KeyName=$sshkey_vm3_name \
    sshDynamicSpoke1Vm1KeyName=$sshkey_vm4_name \
    sshDynamicSpoke2Vm1KeyName=$sshkey_vm5_name \
    sshHub2Vm1KeyName=$sshkey_vm6_name \
    resourceGroupName=$resourceGroup \
    createHub1Vm=true \
    createHub2Vm=true \
    createStaticSpoke1Vm=true \
    createStaticSpoke2Vm=true \
    createDynamicSpoke1Vm=true \
    createDynamicSpoke2Vm=true \
    createGateway=true \
    principalId=$(az ad signed-in-user show --query id -o tsv)


hub1Vm1PrivateIPAddress=$(az deployment group show -g ${resourceGroup}  -n create_hub_spoke_topology   --query "properties.outputs.hub1Vm1PrivateIPAddress.value" -o tsv) 
hub2Vm1PrivateIPAddress=$(az deployment group show -g ${resourceGroup}  -n create_hub_spoke_topology   --query "properties.outputs.hub2Vm1PrivateIPAddress.value" -o tsv)
staticSpoke1Vm1PrivateIPAddress=$(az deployment group show -g ${resourceGroup}  -n create_hub_spoke_topology   --query "properties.outputs.staticSpoke1Vm1PrivateIPAddress.value" -o tsv) 
staticSpoke2Vm1PrivateIPAddress=$(az deployment group show -g ${resourceGroup}  -n create_hub_spoke_topology   --query "properties.outputs.staticSpoke2Vm1PrivateIPAddress.value" -o tsv) 
dynamicSpoke1Vm1PrivateIPAddress=$(az deployment group show -g ${resourceGroup}  -n create_hub_spoke_topology   --query "properties.outputs.dynamicSpoke1Vm1PrivateIPAddress.value" -o tsv)
dynamicSpoke2Vm1PrivateIPAddress=$(az deployment group show -g ${resourceGroup}  -n create_hub_spoke_topology   --query "properties.outputs.dynamicSpoke2Vm1PrivateIPAddress.value" -o tsv)
dynamicSpoke3Vm1PrivateIPAddress=$(az deployment group show -g ${resourceGroup}  -n create_hub_spoke_topology   --query "properties.outputs.dynamicSpoke3Vm1PrivateIPAddress.value" -o tsv)
hub1Vm1Name=$(az deployment group show -g ${resourceGroup}  -n create_hub_spoke_topology  --query "properties.outputs.hub1Vm1Name.value" -o tsv)
hub2Vm1Name=$(az deployment group show -g ${resourceGroup}  -n create_hub_spoke_topology  --query "properties.outputs.hub2Vm1Name.value" -o tsv)
vpnGateWayName=$(az deployment group show -g ${resourceGroup}  -n create_hub_spoke_topology  --query "properties.outputs.vpnGateWayName.value" -o tsv)
staticSpoke1Vm1Name=$(az deployment group show -g ${resourceGroup}  -n create_hub_spoke_topology  --query "properties.outputs.staticSpoke1Vm1Name.value" -o tsv)
staticSpoke2Vm1Name=$(az deployment group show -g ${resourceGroup}  -n create_hub_spoke_topology  --query "properties.outputs.staticSpoke2Vm1Name.value" -o tsv)
dynamicSpoke1Vm1Name=$(az deployment group show -g ${resourceGroup}  -n create_hub_spoke_topology  --query "properties.outputs.dynamicSpoke1Vm1Name.value" -o tsv)
dynamicSpoke2Vm1Name=$(az deployment group show -g ${resourceGroup}  -n create_hub_spoke_topology  --query "properties.outputs.dynamicSpoke2Vm1Name.value" -o tsv)


echo $hub1Vm1Name $hub1Vm1PrivateIPAddress $hub2Vm1Name $hub2Vm1PrivateIPAddress $staticSpoke1Vm1PrivateIPAddress $staticSpoke2Vm1PrivateIPAddress $dynamicSpoke1Vm1PrivateIPAddress $dynamicSpoke2Vm1PrivateIPAddress $vpnGateWayName
echo $staticSpoke1Vm1Name $staticSpoke2Vm1Name $dynamicSpoke1Vm1Name $dynamicSpoke2Vm1Name 

# Download client VPN config file
clientVPNConfigFileURL=$(az network vnet-gateway vpn-client generate --name $vpnGateWayName --resource-group ${resourceGroup})
clientVPNConfigFileURL="${clientVPNConfigFileURL//\"/}"
echo $clientVPNConfigFileURL
curl -o vpnClientConfig.zip $clientVPNConfigFileURL
unzip -o vpnClientConfig.zip 

#VPN to Vnet1

alias sshStaticSpoke1Vm1='ssh -i ~/.ssh/$key_file2_name gary@$staticSpoke1Vm1PrivateIPAddress'

sshStaticSpoke1Vm1 "ping -c 3 $hub2Vm1PrivateIPAddress"
sshStaticSpoke1Vm1 "ping -c 3 $dynamicSpoke1Vm1PrivateIPAddress"
sshStaticSpoke1Vm1 "ping -c 3 $dynamicSpoke2Vm1PrivateIPAddress"

az vm run-command invoke   --resource-group $resourceGroup   --name $dynamicSpoke1Vm1Name   --command-id RunShellScript  --scripts "ping -c 3 $staticSpoke1Vm1PrivateIPAddress" 
az vm run-command invoke   --resource-group $resourceGroup   --name $dynamicSpoke1Vm1Name   --command-id RunShellScript  --scripts "ping -c 3 $staticSpoke2Vm1PrivateIPAddress" 
az vm run-command invoke   --resource-group $resourceGroup   --name $dynamicSpoke1Vm1Name   --command-id RunShellScript  --scripts "ping -c 3 $hub1Vm1PrivateIPAddress" 


#*************************Clean up********************************************************************************************************************************************

#Clean up
az group delete --name ${resourceGroup} --yes --no-wait

rm  ~/.ssh/*
