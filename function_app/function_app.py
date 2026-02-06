import azure.functions as func
import logging
import json
import os
from azure.cosmos import CosmosClient, exceptions

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)


def get_cosmos_client():
    """
    Initialize and return Cosmos DB client.
    Uses environment variables for connection details.
    """
    endpoint = os.environ.get("COSMOS_ENDPOINT")
    key = os.environ.get("COSMOS_KEY")
    
    if not endpoint or not key:
        raise ValueError("COSMOS_ENDPOINT and COSMOS_KEY environment variables must be set")
    
    return CosmosClient(endpoint, key)


@app.route(route="visitor", methods=["GET", "POST"])
def visitor_counter(req: func.HttpRequest) -> func.HttpResponse:
    """
    HTTP trigger function to handle visitor count.
    GET: Returns the current visitor count
    POST: Increments the visitor count and returns the new value
    """
    logging.info('Visitor counter function processed a request.')
    
    try:
        client = get_cosmos_client()
        
        database_name = os.environ.get("COSMOS_DATABASE_NAME", "resume-dev-sqldb")
        container_name = os.environ.get("COSMOS_CONTAINER_NAME", "resume-dev-sqlcnt")
        
        database = client.get_database_client(database_name)
        container = database.get_container_client(container_name)
        
        visitor_id = "visitor_count"
        
        if req.method == "GET":
            # Get current visitor count
            try:
                item = container.read_item(item=visitor_id, partition_key="counter")
                count = item.get("count", 0)
            except exceptions.CosmosResourceNotFoundError:
                count = 0
            
            return func.HttpResponse(
                json.dumps({"count": count}),
                mimetype="application/json",
                status_code=200
            )
        
        elif req.method == "POST":
            # Increment visitor count
            try:
                item = container.read_item(item=visitor_id, partition_key="counter")
                item["count"] = item.get("count", 0) + 1
                container.upsert_item(item)
                count = item["count"]
            except exceptions.CosmosResourceNotFoundError:
                # Create new counter if doesn't exist
                new_item = {
                    "id": visitor_id,
                    "userId": "counter",
                    "count": 1
                }
                container.create_item(new_item)
                count = 1
            
            return func.HttpResponse(
                json.dumps({"count": count}),
                mimetype="application/json",
                status_code=200
            )
    
    except ValueError as ve:
        logging.error(f"Configuration error: {str(ve)}")
        return func.HttpResponse(
            json.dumps({"error": "Server configuration error"}),
            mimetype="application/json",
            status_code=500
        )
    except Exception as e:
        logging.error(f"Error processing request: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Internal server error"}),
            mimetype="application/json",
            status_code=500
        )


@app.route(route="resume", methods=["GET"])
def get_resume_data(req: func.HttpRequest) -> func.HttpResponse:
    """
    HTTP trigger function to retrieve resume data from Cosmos DB.
    Returns all resume-related data stored in the container.
    """
    logging.info('Resume data function processed a request.')
    
    try:
        client = get_cosmos_client()
        
        database_name = os.environ.get("COSMOS_DATABASE_NAME", "resume-dev-sqldb")
        container_name = os.environ.get("COSMOS_CONTAINER_NAME", "resume-dev-sqlcnt")
        
        database = client.get_database_client(database_name)
        container = database.get_container_client(container_name)
        
        # Query parameter to filter by type (e.g., experience, education, skills)
        data_type = req.params.get('type')
        
        if data_type:
            query = f"SELECT * FROM c WHERE c.type = @type"
            parameters = [{"name": "@type", "value": data_type}]
            items = list(container.query_items(
                query=query,
                parameters=parameters,
                enable_cross_partition_query=True
            ))
        else:
            # Return all items
            query = "SELECT * FROM c WHERE c.type != 'counter' OR NOT IS_DEFINED(c.type)"
            items = list(container.query_items(
                query=query,
                enable_cross_partition_query=True
            ))
        
        return func.HttpResponse(
            json.dumps({"data": items}),
            mimetype="application/json",
            status_code=200
        )
    
    except ValueError as ve:
        logging.error(f"Configuration error: {str(ve)}")
        return func.HttpResponse(
            json.dumps({"error": "Server configuration error"}),
            mimetype="application/json",
            status_code=500
        )
    except Exception as e:
        logging.error(f"Error processing request: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Internal server error"}),
            mimetype="application/json",
            status_code=500
        )


@app.route(route="health", methods=["GET"])
def health_check(req: func.HttpRequest) -> func.HttpResponse:
    """
    Health check endpoint for monitoring.
    """
    logging.info('Health check function processed a request.')
    
    return func.HttpResponse(
        json.dumps({"status": "healthy", "service": "resume-api"}),
        mimetype="application/json",
        status_code=200
    )
