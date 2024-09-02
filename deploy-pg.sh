#!/bin/bash

# Set environment variables
export pgo_cluster_name="test"
export cluster_namespace="pgo"
export cluster_image_prefix="registry.developers.crunchydata.com/crunchydata"
export pgo_operator_namespace="pgo"  # Define the PGO operator namespace
export pgo_cluster_username="hippo"  # Define the PostgreSQL cluster username

# Retrieve PostgreSQL user password
export PGPASSWORD=$(oc -n "${pgo_operator_namespace}" get secrets \
  "${pgo_cluster_name}-${pgo_cluster_username}-secret" -o "jsonpath={.data['password']}" | base64 -d)

# Access the PostgreSQL cluster
psql -h localhost -U "${pgo_cluster_username}" "${pgo_cluster_name}"

# Define Pgcluster YAML configuration
cat <<EOF > "${pgo_cluster_name}-pgcluster.yaml"
apiVersion: crunchydata.com/v1
kind: Pgcluster
metadata:
  name: ${pgo_cluster_name}
  namespace: ${cluster_namespace}
  labels:
    crunchy-pgha-scope: ${pgo_cluster_name}
    deployment-name: ${pgo_cluster_name}
    pg-cluster: ${pgo_cluster_name}
    pgo-version: 4.7.0
    pgouser: admin
  annotations:
    current-primary: ${pgo_cluster_name}
spec:
  ccpimage: crunchy-postgres-ha
  ccpimageprefix: ${cluster_image_prefix}
  ccpimagetag: centos8-13.3-4.7.0
  clustername: ${pgo_cluster_name}
  database: ${pgo_cluster_name}
  user: ${pgo_cluster_username}
  port: "5432"
  exporterport: "9187"
  pgbadgerport: "10000"
  pgoimageprefix: ${cluster_image_prefix}

  # Storage Configuration
  PrimaryStorage:
    accessmode: ReadWriteMany
    name: ${pgo_cluster_name}
    size: 100Gi
    storagetype: create
  BackrestStorage:
    accessmode: ReadWriteMany
    size: 100Gi
    storagetype: create
  ReplicaStorage:
    accessmode: ReadWriteMany
    size: 100Gi
    storagetype: create

  # Pod Affinity and Tolerations
  podAntiAffinity:
    default: preferred
    pgBackRest: preferred
    pgBouncer: preferred
  tolerations: []

  # Optional settings for restoring data
  pgDataSource:
    restoreFrom: ""
    restoreOpts: ""

  # Optional resource limits
  limits: {}

  # User labels
  userlabels:
    pgo-version: 4.7.0
EOF

# Apply the Pgcluster configuration
oc apply -f "${pgo_cluster_name}-pgcluster.yaml"
