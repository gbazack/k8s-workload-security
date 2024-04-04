#!/bin/bash

# Generate a random Base64 encoded key with OpenSSL

openssl rand -base64 -out key-base64.pem 32

# Format the key before importing it to Google Cloud KMS

cat key-base64.pem | base64 -d > key.pem
file key.pem
# The output of the second command should be data

# Set up automatic key wrapping
sudo apt-get update
sudo apt-get install python3-cryptography
# Version of the python-cryptography package >= 2.2.0

# Enable site packages to allow the Google Cloud CLI to use the Pyca cryptographic library

export CLOUDSDK_PYTHON_SITEPACKAGES=1

# Create a keyring (if it does not exist)
gcloud kms keyrings --project=GOOGLE_PROJECT create cmek-opensee-test-keyring --location=EUROPE_REGION

# Create the target key for the CMEK
gcloud kms keys --project=GOOGLE_PROJECT create cmek-opensee-test-key \
        --location=EUROPE_REGION \
        --keyring=cmek-opensee-test-keyring \
        --purpose encryption \
        --skip-initial-version-creation \
        --import-only

# Create an import job
gcloud kms import-jobs --project=GOOGLE_PROJECT create cmek-opensee-test-import-job \
        --location=EUROPE_REGION \
        --keyring=cmek-opensee-test-keyring \
        --import-method=rsa-oaep-4096-sha256-aes-256 \
        --protection-level=software

# Check the state of the import job
gcloud kms import-jobs --project=GOOGLE_PROJECT describe cmek-opensee-test-import-job \
        --keyring=cmek-opensee-test-keyring \
        --location=EUROPE_REGION \
        --format='value(state)'
# The output is similar to the following: ACTIVE

# Automatically wrapping and importing a key
gcloud kms keys --project=GOOGLE_PROJECT versions import \
        --import-job=cmek-opensee-test-import-job \
        --location=EUROPE_REGION \
        --keyring=cmek-opensee-test-keyring \
        --key=cmek-opensee-test-key \
        --algorithm=google-symmetric-encryption \
        --target-key-file=PATH_TO/key.pem
# The initial state for an imported key version is PENDING_IMPORT

# Check the state of the imported key version
gcloud kms keys --project=GOOGLE_PROJECT versions list \
        --keyring=cmek-opensee-test-keyring \
        --location=EUROPE_REGION \
        --key=cmek-opensee-test-key
# KEY_VERSION is usually 1, because the imported version is the first version of the key

# Set the imported key version as the primary version
gcloud kms keys --project=GOOGLE_PROJECT set-primary-version cmek-opensee-test-key \
        --location=EUROPE_REGION \
        --keyring=cmek-opensee-test-keyring \
        --version=1