## Elasticsearch Read-Only Block Resolution Guide

### Problem Description

When running Elasticsearch in a single-node Docker setup, you may encounter the following error:

> elasticsearch.exceptions.AuthorizationException:
> AuthorizationException(403, 'cluster_block_exception', 'blocked by:
> [FORBIDDEN/12/index read-only / allow delete (api)];')

This error occurs when Elasticsearch indices enter a read-only state, preventing any write operations.
### Root Causes

#### 1: Unassigned Replica Shards

-   **Default Elasticsearch settings**: 5 primary shards + 1 replica per shard
    
-   **Single-node limitation**: Replicas cannot be assigned to the same node as primaries
    
-   **Result**: 5 unassigned replica shards causing yellow cluster status
    
-   **Automatic protection**: Elasticsearch triggers read-only mode to prevent data corruption

#### 2: Disk Space Monitoring

-   Elasticsearch monitors host disk usage, not container-specific usage
    
-   Default flood stage watermark: 95% disk usage
    
-   If host disk exceeds 95%, read-only block is automatically applied

### Commands to diagnose the root cause:

 1. Check cluster health:
 It shows "unassigned_shards" and "status". Status should be 'green' ideally.

    ```curl -XGET 'localhost:9200/_cluster/health?pretty'```

 2. Check matchminer index setting in ES (nodes/replicas/shards):
 If it shows "index.blocks.read_only_allow_delete": "true", that means it has set itself to read-only mode.

    ```curl -XGET 'localhost:9200/matchminer/_settings?pretty&flat_settings=true'```

3. Check disk watermarks specifically:

    ```curl -XGET 'localhost:9200/_cluster/settings?include_defaults=true&pretty' | grep -A 5 -B 5 watermark```

### Solutions
1. Try to remove read-only block:

```
curl -XPUT -H "Content-Type: application/json" 'localhost:9200/_all/_settings?pretty' -d '{  "index.blocks.read_only_allow_delete": null}'
```

2. If the host machine's disk usage %age is above the 'watermark.flood_stage' %age, either free up space in host machine or change the setting in Elastic Search
#### Adjust Disk Watermarks (if disk space is tight)

```
 curl -XPUT -H "Content-Type: application/json" 'localhost:9200/_cluster/settings?pretty' -d '{
          "transient": {
            "cluster.routing.allocation.disk.watermark.low": "90%",
            "cluster.routing.allocation.disk.watermark.high": "95%", 
            "cluster.routing.allocation.disk.watermark.flood_stage": "98%"
          }
        }'
```
3. Configure replicas and shards in application code where indices are being created:

```
 es.indices.create(
      index='matchminer',
      body={
          'settings': {
              'number_of_shards': 1,           # Optimize for single node
              'number_of_replicas': 0,         # Critical for single node
              'refresh_interval': '30s'        # Reduce indexing overhead
          }
      }
  )
```

#### Common Pitfalls
- Don't set index-level settings in elasticsearch.yml - use API or templates

- Check host disk space, not just container usage

- Single-node clusters don't benefit from replicas - always set to 0

- Docker containers share host disk space - monitor overall system usage
