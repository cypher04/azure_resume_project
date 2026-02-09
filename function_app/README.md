# Azure Functions - Resume API

This Azure Functions app provides HTTP-triggered APIs to interact with Cosmos DB for the resume website.

## Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/visitor` | GET | Get current visitor count |
| `/api/visitor` | POST | Increment visitor count and return new value |
| `/api/resume` | GET | Get all resume data from Cosmos DB |
| `/api/resume?type=<type>` | GET | Get resume data filtered by type |
| `/api/health` | GET | Health check endpoint |

## Environment Variables

Set these in `local.settings.json` for local development or in Azure Function App settings for production:

| Variable | Description |
|----------|-------------|
| `COSMOS_ENDPOINT` | Cosmos DB account endpoint URL |
| `COSMOS_KEY` | Cosmos DB primary or secondary key |
| `COSMOS_DATABASE_NAME` | Name of the Cosmos DB database |
| `COSMOS_CONTAINER_NAME` | Name of the Cosmos DB container |

## Local Development

### Prerequisites
- Python 3.8+
- Azure Functions Core Tools v4
- Azure Storage Emulator (Azurite) for local development

### Setup

1. Create and activate a virtual environment:
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # On macOS/Linux
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Update `local.settings.json` with your Cosmos DB credentials.

4. Start the function app:
   ```bash
   func start
   ```

## Deployment

Deploy to Azure using Azure Functions Core Tools:

```bash
func azure functionapp publish <YOUR_FUNCTION_APP_NAME>
```

## Website Integration

Add these environment variables to your Azure Function App in the Azure Portal or via Terraform:

```hcl
app_settings = {
  COSMOS_ENDPOINT       = azurerm_cosmosdb_account.cosmosdb.endpoint
  COSMOS_KEY            = azurerm_cosmosdb_account.cosmosdb.primary_key
  COSMOS_DATABASE_NAME  = azurerm_cosmosdb_sql_database.sqldb.name
  COSMOS_CONTAINER_NAME = azurerm_cosmosdb_sql_container.sqlcnt.name
}
```

## Sample JavaScript Integration

```javascript
// Fetch and update visitor count
async function updateVisitorCount() {
    const response = await fetch('https://<your-function-app>.azurewebsites.net/api/visitor', {
        method: 'POST'
    });
    const data = await response.json();
    document.getElementById('visitor-count').textContent = data.count;
}

// Fetch resume data
async function loadResumeData() {
    const response = await fetch('https://<your-function-app>.azurewebsites.net/api/resume');
    const data = await response.json();
    return data.data;
}
```
