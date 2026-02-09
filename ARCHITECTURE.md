# Azure Cloud Resume — Architecture Documentation

> **Project:** Cloud Resume Challenge on Azure  
> **IaC Tool:** Terraform (AzureRM Provider ~> 3.0)  
> **Region:** West Europe  
> **Environments:** dev · stage · prod  

---

## High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              AZURE CLOUD (West Europe)                              │
│                                                                                     │
│  ┌───────────────────────────────────────────────────────────────────────────────┐   │
│  │                 Resource Group: rg-resumeproject-{env}-new                    │   │
│  │                                                                               │   │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐   │   │
│  │  │                        NETWORKING (Hub & Spoke)                         │   │   │
│  │  │                                                                         │   │   │
│  │  │   ┌───────────────────────┐       ┌───────────────────────────────┐     │   │   │
│  │  │   │   HUB VNet            │       │   SPOKE VNet                  │     │   │   │
│  │  │   │   10.0.0.0/16         │◄─────►│   10.2.0.0/16                 │     │   │   │
│  │  │   │                       │ Peer  │                               │     │   │   │
│  │  │   │  ┌─────────────────┐  │       │  ┌─────────────────────────┐  │     │   │   │
│  │  │   │  │  hub-subnet     │  │       │  │  spoke-subnet (web)     │  │     │   │   │
│  │  │   │  │  10.0.3.0/24    │  │       │  │  10.2.1.0/24            │  │     │   │   │
│  │  │   │  │  (Database)     │  │       │  │  (Function App VNet     │  │     │   │   │
│  │  │   │  │                 │  │       │  │   Integration)          │  │     │   │   │
│  │  │   │  └─────────────────┘  │       │  └─────────────────────────┘  │     │   │   │
│  │  │   │                       │       │  ┌─────────────────────────┐  │     │   │   │
│  │  │   │                       │       │  │  spoke-subnet-2 (app)   │  │     │   │   │
│  │  │   │                       │       │  │  10.2.2.0/24            │  │     │   │   │
│  │  │   │                       │       │  └─────────────────────────┘  │     │   │   │
│  │  │   │                       │       │  ┌─────────────────────────┐  │     │   │   │
│  │  │   │                       │       │  │  spoke-subnet-3 (func)  │  │     │   │   │
│  │  │   │                       │       │  │  10.2.3.0/24            │  │     │   │   │
│  │  │   │                       │       │  └─────────────────────────┘  │     │   │   │
│  │  │   └───────────────────────┘       └───────────────────────────────┘     │   │   │
│  │  │                                                                         │   │   │
│  │  │   ┌──────────────────────┐                                              │   │   │
│  │  │   │  Public IP (Static)  │  Standard SKU — currently unattached         │   │   │
│  │  │   └──────────────────────┘                                              │   │   │
│  │  └─────────────────────────────────────────────────────────────────────────┘   │   │
│  │                                                                               │   │
│  │  ┌──────────────────────────┐  ┌────────────────────────────────────────────┐  │   │
│  │  │       COMPUTE            │  │              DATABASE                      │  │   │
│  │  │                          │  │                                            │  │   │
│  │  │  ┌────────────────────┐  │  │  ┌──────────────────────────────────────┐  │  │   │
│  │  │  │  Storage Account   │  │  │  │  Azure Cosmos DB (Serverless)        │  │  │   │
│  │  │  │  (Static Website)  │  │  │  │  Kind: GlobalDocumentDB (SQL API)    │  │  │   │
│  │  │  │  ───────────────── │  │  │  │  Consistency: Session                │  │  │   │
│  │  │  │  • Tier: Standard  │  │  │  │  Public Access: Disabled             │  │  │   │
│  │  │  │  • Replication: LRS│  │  │  │                                      │  │  │   │
│  │  │  │  • Static Website  │  │  │  │  ┌──────────────────────────────┐    │  │  │   │
│  │  │  │    ├─ index.html   │  │  │  │  │  SQL Database                │    │  │  │   │
│  │  │  │    └─ 404.html     │  │  │  │  │  resumeproject-{env}-sqldb   │    │  │  │   │
│  │  │  │  • Container:      │  │  │  │  │                              │    │  │  │   │
│  │  │  │    "content"       │  │  │  │  │  ┌──────────────────────┐    │    │  │  │   │
│  │  │  │    (Private)       │  │  │  │  │  │  SQL Container       │    │    │  │  │   │
│  │  │  └────────────────────┘  │  │  │  │  │  Partition: /userId  │    │    │  │  │   │
│  │  │                          │  │  │  │  └──────────────────────┘    │    │  │  │   │
│  │  │  ┌────────────────────┐  │  │  │  └──────────────────────────────┘    │  │  │   │
│  │  │  │  Storage Account   │  │  │  └──────────────────────────────────────┘  │  │   │
│  │  │  │  (Function App)    │  │  │                                            │  │   │
│  │  │  │  ───────────────── │  │  │  ┌──────────────────────────────────────┐  │  │   │
│  │  │  │  • Tier: Standard  │  │  │  │  Private Endpoint (Cosmos DB)        │  │  │   │
│  │  │  │  • Replication: LRS│  │  │  │  ──────────────────────────────      │  │  │   │
│  │  │  │  • Managed Identity│  │  │  │  • Subnet: hub-subnet               │  │  │   │
│  │  │  └────────────────────┘  │  │  │  • Sub-resource: Sql                 │  │  │   │
│  │  │                          │  │  │  • DNS Zone:                          │  │  │   │
│  │  │  ┌────────────────────┐  │  │  │    privatelink.documents.azure.com   │  │  │   │
│  │  │  │  App Service Plan  │  │  │  │  • DNS VNet Link → Hub VNet          │  │  │   │
│  │  │  │  (Consumption Y1)  │  │  │  └──────────────────────────────────────┘  │  │   │
│  │  │  │  OS: Linux         │  │  └────────────────────────────────────────────┘  │   │
│  │  │  └────────┬───────────┘  │                                                 │   │
│  │  │           │              │  ┌────────────────────────────────────────────┐  │   │
│  │  │  ┌────────▼───────────┐  │  │             SECRETS                       │  │   │
│  │  │  │  Linux Function    │  │  │                                            │  │   │
│  │  │  │  App (Python 3.11) │  │  │  ┌──────────────────────────────────────┐  │  │   │
│  │  │  │  ──────────────────│  │  │  │  Azure Key Vault (Standard)          │  │  │   │
│  │  │  │  Auth: Anonymous   │  │  │  │  ──────────────────────────────      │  │  │   │
│  │  │  │  Runtime: Python   │  │  │  │  • Soft Delete: 7 days               │  │  │   │
│  │  │  │                    │  │  │  │  • Purge Protection: Enabled          │  │  │   │
│  │  │  │  Endpoints:        │  │  │  │  • Disk Encryption: Enabled          │  │  │   │
│  │  │  │  ├─ /api/visitor   │  │  │  │                                      │  │  │   │
│  │  │  │  │  (GET/POST)     │  │  │  │  Secrets:                            │  │  │   │
│  │  │  │  ├─ /api/resume    │  │  │  │  ├─ CosmosDBKey                      │  │  │   │
│  │  │  │  │  (GET)          │  │  │  │  ├─ CosmosDBAccountId                │  │  │   │
│  │  │  │  └─ /api/health    │  │  │  │  ├─ CosmosDBEndpoint                 │  │  │   │
│  │  │  │     (GET)          │  │  │  │  ├─ CosmosDBContainerName            │  │  │   │
│  │  │  │                    │  │  │  │  └─ CosmosDBDatabaseName             │  │  │   │
│  │  │  │  VNet Integration: │  │  │  │                                      │  │  │   │
│  │  │  │  → spoke-subnet    │  │  │  │  Access Policy:                      │  │  │   │
│  │  │  │                    │  │  │  │  └─ Function App (Get, List)          │  │  │   │
│  │  │  │  CORS Origins:     │  │  │  └──────────────────────────────────────┘  │  │   │
│  │  │  │  ├─ Azure Portal   │  │  └────────────────────────────────────────────┘  │   │
│  │  │  │  └─ Static Website │  │                                                 │   │
│  │  │  │    (*.web.core...) │  │                                                 │   │
│  │  │  └────────────────────┘  │                                                 │   │
│  │  └──────────────────────────┘                                                 │   │
│  └───────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                     │
│  ┌───────────────────────────────────────────────────────────────────────────────┐   │
│  │          Terraform State Backend (Separate Resource Group)                    │   │
│  │          RG: myprojectdev-rg-new                                              │   │
│  │                                                                               │   │
│  │   ┌──────────────────────────────────────────────────┐                        │   │
│  │   │  Storage Account: myprojectstatedevresume        │                        │   │
│  │   │  ├─ TLS 1.2 minimum                             │                        │   │
│  │   │  ├─ HTTPS only                                   │                        │   │
│  │   │  ├─ Blob versioning enabled                      │                        │   │
│  │   │  ├─ Delete retention: 30 days                    │                        │   │
│  │   │  └─ Container: "tfstate" (Private)               │                        │   │
│  │   └──────────────────────────────────────────────────┘                        │   │
│  └───────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow Diagram

```
                         ┌──────────────┐
                         │   Browser    │
                         │   (User)     │
                         └──────┬───────┘
                                │
               ┌────────────────┼────────────────────┐
               │ HTTPS (Public) │                    │
               ▼                │                    │
    ┌──────────────────┐        │                    │
    │  Static Website  │        │                    │
    │  (Blob Storage)  │        │                    │
    │  ─────────────── │        │                    │
    │  • index.html    │        │                    │
    │  • style.css     │        │                    │
    │  • main.js       │        │                    │
    │                  │        │                    │
    │  Public Endpoint │        │                    │
    │  *.z13.web.core  │        │                    │
    │  .windows.net    │        │                    │
    └────────┬─────────┘        │                    │
             │                  │                    │
             │  JS fetch()      │                    │
             │  /api/visitor    │                    │
             │  /api/resume     │                    │
             └──────────────────┘                    │
                                │                    │
                                │ (Public access     │
                                │  DISABLED —        │
                                │  requires Private  │
                                │  Endpoint or VNet  │
                                │  integration for   │
                                │  inbound access)   │
                                │                    │
                    ┌───────────▼──────────────┐     │
                    │  Azure Function App       │     │
                    │  (Python 3.11 / Linux)    │     │
                    │  ────────────────────     │     │
                    │  Public Access: DISABLED  │     │
                    │                           │     │
                    │  Endpoints:               │     │
                    │  ├─ /api/visitor (GET/POST)│     │
                    │  ├─ /api/resume  (GET)    │     │
                    │  └─ /api/health  (GET)    │     │
                    │                           │     │
                    │  CORS:                    │     │
                    │  ├─ Azure Portal          │     │
                    │  └─ Static Website origin │     │
                    │                           │     │
                    │  VNet Integration:        │     │
                    │  → spoke-subnet           │     │
                    │    (10.2.1.0/24)          │     │
                    └──────┬───────────┬────────┘     │
                           │           │              │
          ┌────────────────┘           └───────────┐  │
          │ Key Vault Reference                    │  │
          │ @Microsoft.KeyVault(SecretUri=...)      │  │
          ▼                                        │  │
┌──────────────────────┐                           │  │
│  Azure Key Vault     │                           │  │
│  (Standard SKU)      │                           │  │
│  ──────────────────  │                           │  │
│  Secrets:            │                           │  │
│  ├─ CosmosDBKey      │                           │  │
│  ├─ CosmosDBEndpoint │                           │  │
│  ├─ CosmosDBAccountId│                           │  │
│  ├─ CosmosDBContainer│                           │  │
│  │    Name           │                           │  │
│  └─ CosmosDBDatabase │                           │  │
│       Name           │                           │  │
│                      │                           │  │
│  Access Policy:      │                           │  │
│  └─ Function App     │                           │  │
│     (Get, List)      │                           │  │
└──────────┬───────────┘                           │  │
           │ Secrets resolved at runtime           │  │
           └──────────┐                            │  │
                      ▼                            │  │
           ┌──────────────────────────────────┐    │  │
           │  Azure Cosmos DB (Serverless)    │    │  │
           │  SQL API / GlobalDocumentDB      │    │  │
           │  ──────────────────────────────  │    │  │
           │  Public Access: DISABLED         │◄───┘  │
           │                                  │       │
           │  ┌────────────────────────────┐  │       │
           │  │  SQL Database              │  │       │
           │  │  resumeproject-{env}-sqldb  │  │       │
           │  │                            │  │       │
           │  │  ┌──────────────────────┐  │  │       │
           │  │  │  SQL Container       │  │  │       │
           │  │  │  Partition: /userId  │  │  │       │
           │  │  │                      │  │  │       │
           │  │  │  Data:               │  │  │       │
           │  │  │  ├─ Visitor Counter  │  │  │       │
           │  │  │  │  (id: visitor_    │  │  │       │
           │  │  │  │   count)          │  │  │       │
           │  │  │  └─ Resume Data      │  │  │       │
           │  │  │     (experience,     │  │  │       │
           │  │  │      education, etc) │  │  │       │
           │  │  └──────────────────────┘  │  │       │
           │  └────────────────────────────┘  │       │
           │                                  │       │
           │  Private Endpoint:               │       │
           │  └─ hub-subnet (10.0.3.0/24)     │       │
           │     DNS: privatelink.documents   │       │
           │          .azure.com              │       │
           └──────────────────────────────────┘       │
                                                      │
```

### Request Flow (Step by Step)

```
1. User visits static website URL (*.z13.web.core.windows.net)
2. Browser loads index.html, style.css, main.js
3. main.js calls Function App API (/api/visitor POST)
   ⚠ NOTE: Function App has public_network_access = false
   → Requires Private Endpoint for inbound traffic (currently commented out)
4. Function App resolves Cosmos DB secrets via Key Vault references
5. Function App routes outbound traffic through spoke-subnet (VNet Integration)
6. Traffic flows via VNet Peering (spoke → hub)
7. Cosmos DB Private Endpoint in hub-subnet receives the request
8. Private DNS Zone resolves *.documents.azure.com → private IP
9. Cosmos DB processes query and returns visitor count
10. Response flows back: Cosmos DB → Function App → Browser
```

---

## Network Topology — Hub & Spoke

```
                        ┌───────────────────────────┐
                        │         INTERNET           │
                        └─────────────┬─────────────┘
                                      │
                              ┌───────▼───────┐
                              │  Public IP     │
                              │  (Static/Std)  │
                              │  [Unattached]  │
                              └───────────────┘

    ┌──────────────────────────────┐         ┌──────────────────────────────────────┐
    │  HUB VNet (10.0.0.0/16)     │◄═══════►│  SPOKE VNet (10.2.0.0/16)            │
    │                              │  Peering │                                      │
    │  ┌────────────────────────┐  │ (Bidir.) │  ┌──────────────────────────────┐    │
    │  │  hub-subnet            │  │         │  │  spoke-subnet (web)           │    │
    │  │  10.0.3.0/24           │  │         │  │  10.2.1.0/24                  │    │
    │  │                        │  │         │  │  → Function App VNet Integ.   │    │
    │  │  ┌──────────────────┐  │  │         │  └──────────────────────────────┘    │
    │  │  │ Cosmos DB         │  │  │         │  ┌──────────────────────────────┐    │
    │  │  │ Private Endpoint  │  │  │         │  │  spoke-subnet-2 (app)        │    │
    │  │  └──────────────────┘  │  │         │  │  10.2.2.0/24                  │    │
    │  └────────────────────────┘  │         │  └──────────────────────────────┘    │
    │                              │         │  ┌──────────────────────────────┐    │
    │                              │         │  │  spoke-subnet-3 (function)   │    │
    │                              │         │  │  10.2.3.0/24                  │    │
    │                              │         │  └──────────────────────────────┘    │
    └──────────────────────────────┘         └──────────────────────────────────────┘

    Peering Config:
    ├─ allow_forwarded_traffic = true
    ├─ allow_gateway_transit   = false
    └─ use_remote_gateways     = false
```

---

## Private Endpoint & DNS Resolution

```
    Function App                      Hub VNet
    (spoke-subnet VNet Integration)   (hub-subnet)
         │                                │
         │  Outbound via VNet Peering     │
         ├───────────────────────────────►│
         │                                │
         │               ┌────────────────▼──────────────────┐
         │               │  Cosmos DB Private Endpoint        │
         │               │  Sub-resource: Sql                 │
         │               │                                    │
         │               │  Private DNS Zone:                 │
         │               │  privatelink.documents.azure.com   │
         │               │  Linked to: Hub VNet               │
         │               │                                    │
         │               │  Resolves:                         │
         │               │  *.documents.azure.com             │
         │               │  → Private IP in hub-subnet        │
         │               └────────────────────────────────────┘
```

---

## IAM & Role Assignments

```
┌──────────────────────────────────┐
│  Function App (Managed Identity) │
│  SystemAssigned                   │
└───────────┬──────────────────────┘
            │
            ├──► Cosmos DB Account
            │    Role: "Cosmos DB Built-in Data Contributor"
            │    (Read + Write access to data plane)
            │
            ├──► Function Storage Account
            │    Role: "Storage Blob Data Contributor"
            │    (Read + Write blobs)
            │
            └──► Key Vault
                 Access Policy: Get, List (Secrets)
                 (Retrieve Cosmos DB credentials at runtime)
```

---

## Terraform Module Dependency Graph

```
                    ┌───────────────────────┐
                    │     env/dev/main.tf    │
                    │  (Root Configuration)  │
                    └───────────┬───────────┘
                                │
                ┌───────────────┼───────────────┐
                │               │               │
                ▼               ▼               ▼
      ┌─────────────┐  ┌──────────────┐  ┌──────────────┐
      │  module.     │  │  module.     │  │  module.     │
      │  networking  │  │  database    │  │  compute     │
      │              │  │              │  │              │
      │  • Hub VNet  │  │  • Cosmos DB │  │  • Storage   │
      │  • Spoke VNet│  │  • SQL DB    │  │  • Website   │
      │  • Subnets   │  │  • Container │  │  • Func App  │
      │  • Peering   │  │              │  │  • Key Vault │
      │  • Public IP │  │              │  │  • Secrets   │
      └──────────────┘  └──────┬───────┘  └──────┬───────┘
                               │                  │
                               │   depends_on     │
                               └──────────────────┘

      Outputs flowing database → compute:
      ├─ cosmosdb_account_id
      ├─ cosmosdb_account_primary_key
      ├─ cosmosdb_account_endpoint
      ├─ cosmosdb_database_name
      └─ cosmosdb_container_name

      Root-level resources (env/dev/main.tf):
      ├─ Cosmos DB Private Endpoint (hub-subnet)
      ├─ Private DNS Zone (privatelink.documents.azure.com)
      └─ DNS Zone ↔ Hub VNet Link
```

---

## Resource Inventory

| Resource | Terraform ID | Module | Purpose |
|----------|-------------|--------|---------|
| Resource Group | `azurerm_resource_group.rg-mainn` | Root (env/dev) | Contains all project resources |
| Hub VNet | `azurerm_virtual_network.hub_vnet` | networking | Central network hub (10.0.0.0/16) |
| Spoke VNet | `azurerm_virtual_network.spoke_vnet` | networking | Application workload network (10.2.0.0/16) |
| Hub Subnet | `azurerm_subnet.hub-subnet` | networking | Database private endpoints (10.0.3.0/24) |
| Web Subnet | `azurerm_subnet.spoke-subnet` | networking | Function App VNet integration (10.2.1.0/24) |
| App Subnet | `azurerm_subnet.spoke-subnet-2` | networking | Application tier (10.2.2.0/24) |
| Function Subnet | `azurerm_subnet.spoke-subnet-3` | networking | Reserved for functions (10.2.3.0/24) |
| VNet Peering (Hub→Spoke) | `azurerm_virtual_network_peering.hub_to_spoke` | networking | Bidirectional peering |
| VNet Peering (Spoke→Hub) | `azurerm_virtual_network_peering.spoke_to_hub` | networking | Bidirectional peering |
| Public IP | `azurerm_public_ip.pip` | networking | Static IP (Standard SKU) |
| Storage Account (Website) | `azurerm_storage_account.sta` | compute | Static website hosting |
| Storage Container | `azurerm_storage_container.stc` | compute | Blob container "content" |
| Static Website | `azurerm_storage_account_static_website.sw` | compute | index.html / 404.html hosting |
| Storage Account (FuncApp) | `azurerm_storage_account.func_sta` | compute | Function App backing storage |
| App Service Plan | `azurerm_service_plan.asp` | compute | Linux Consumption (Y1) plan |
| Linux Function App | `azurerm_linux_function_app.function` | compute | Python 3.11 API backend |
| VNet Integration | `azurerm_app_service_virtual_network_swift_connection` | compute | Function → spoke-subnet |
| Cosmos DB Account | `azurerm_cosmosdb_account.cosmosdb` | database | Serverless SQL API database |
| Cosmos DB SQL Database | `azurerm_cosmosdb_sql_database.sqldb` | database | Application database |
| Cosmos DB SQL Container | `azurerm_cosmosdb_sql_container.sqlcnt` | database | Data container (partition: /userId) |
| Key Vault | `azurerm_key_vault.kv` | compute | Secrets management |
| KV Secret: CosmosDBKey | `azurerm_key_vault_secret.cosmosdb_key` | compute | Cosmos DB primary key |
| KV Secret: CosmosDBEndpoint | `azurerm_key_vault_secret.cosmosdb_endpoint` | compute | Cosmos DB endpoint URL |
| KV Secret: CosmosDBAccountId | `azurerm_key_vault_secret.cosmosdb_account_id` | compute | Cosmos DB resource ID |
| KV Secret: CosmosDBContainerName | `azurerm_key_vault_secret.cosmosdb_container_name` | compute | Container name |
| KV Secret: CosmosDBDatabaseName | `azurerm_key_vault_secret.cosmosdb_database_name` | compute | Database name |
| KV Access Policy | `azurerm_key_vault_access_policy.funcapp_kv_access` | compute | Function App → KV (Get, List) |
| Role: Cosmos DB Contributor | `azurerm_role_assignment.func_cosmosdb` | compute | Function App → Cosmos DB data |
| Role: Storage Blob Contributor | `azurerm_role_assignment.funcapp_storageaccount` | compute | Function App → Storage |
| Cosmos DB Private Endpoint | `azurerm_private_endpoint.pe-cosmosdb` | Root (env/dev) | Private access to Cosmos DB |
| Private DNS Zone | `azurerm_private_dns_zone.cosmosdb_pdz` | Root (env/dev) | privatelink.documents.azure.com |
| DNS Zone VNet Link | `azurerm_private_dns_zone_virtual_network_link` | Root (env/dev) | DNS zone → Hub VNet |

---

## Terraform State Backend

```
┌──────────────────────────────────────────┐
│  Resource Group: myprojectdev-rg-new     │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │  Storage Account:                  │  │
│  │  myprojectstatedevresume           │  │
│  │                                    │  │
│  │  Security:                         │  │
│  │  ├─ TLS 1.2 minimum               │  │
│  │  ├─ HTTPS traffic only             │  │
│  │  ├─ Blob versioning enabled        │  │
│  │  └─ Soft delete: 30 days           │  │
│  │                                    │  │
│  │  ┌──────────────────────────────┐  │  │
│  │  │  Container: tfstate          │  │  │
│  │  │  Access: Private             │  │  │
│  │  │  Key: terraform.tfstate      │  │  │
│  │  └──────────────────────────────┘  │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

---

## Multi-Environment Layout

```
azure_resume_project/
├── backend/              ← Terraform state storage (bootstrapped first)
├── modules/
│   ├── networking/       ← Hub-spoke VNets, subnets, peering, public IP
│   ├── compute/          ← Storage, static website, function app, key vault
│   ├── database/         ← Cosmos DB account, database, container
│   └── security/         ← (Placeholder — not yet implemented)
├── env/
│   ├── dev/              ← Development environment root config
│   ├── stage/            ← Staging environment root config
│   └── prod/             ← Production environment root config
├── function_app/         ← Python Azure Functions source code
└── website/              ← Static website (HTML/CSS/JS)
```

---

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/visitor` | `GET` | Returns current visitor count from Cosmos DB |
| `/api/visitor` | `POST` | Increments visitor count, returns new value |
| `/api/resume` | `GET` | Returns resume data (filterable by `?type=`) |
| `/api/health` | `GET` | Health check — returns `{"status": "healthy"}` |

---

## Security Posture Summary

| Layer | Implementation | Status |
|-------|---------------|--------|
| Secrets Management | Key Vault with KV references in app settings | ✅ Implemented |
| Network Isolation | Cosmos DB Private Endpoint + Private DNS | ✅ Implemented |
| VNet Integration | Function App → spoke-subnet | ✅ Implemented |
| Managed Identity | Function App SystemAssigned identity | ✅ Implemented |
| RBAC | Cosmos DB Data Contributor, Storage Blob Contributor | ✅ Implemented |
| CORS | Restricted to Azure Portal + static website origin | ✅ Implemented |
| Cosmos DB Public Access | Disabled (`public_network_access_enabled = false`) | ✅ Implemented |
| NSGs / Firewall | Not defined on any subnet | ❌ Not Implemented |
| WAF / DDoS Protection | Not configured | ❌ Not Implemented |
| CDN | Not configured (commented placeholder) | ❌ Not Implemented |
| Security Module | Empty placeholder | ❌ Not Implemented |
