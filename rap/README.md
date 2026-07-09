**# SCORT RAP Layer

## Owner
Tín

## System
S40 Client 324

## Package
ZSCORT_SAP05

## Objects

### Behavior Definitions
- ZI_SCORT_REPOSITORY_SYNC

### CDS Custom Entities
- ZI_SCORT_REPOSITORY_OBJECT
- ZI_SCORT_REPOSITORY_STATISTICS
- ZI_SCORT_REPOSITORY_SYNC
- ZI_SCORT_SEND_LOG
- ZC_SCORT_SEND_LOG
- ZI_SCORT_SEND_PACKAGE_PARAMS

### Query Providers
- ZCL_SCORT_OBJECT_QUERY
- ZCL_SCORT_STATISTICS_QUERY
- ZCL_SCORT_SYNC_QUERY
- ZBP_SCORT_SYNC

### Function Group
- ZSCORT_FG_LOCAL
  ### Function Modules
  - Z_SCORT_SEND_PACKAGE_LOCAL

### Service
- ZUI_SCORT_SERVICE
- ZUI_SCORT_SERVICE_O4

## Activate Order
1. Query Provider classes
2. CDS custom entities
3. Service Definition
4. Service Binding
5. Publish Service Binding**
