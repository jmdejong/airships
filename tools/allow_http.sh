#!/bin/bash

# Allow the exported web client to also run on http connections instead of just https and localhost
# Useful for development. Don't use in production

sed --in-place 's/if (!Features.isSecureContext())/if (false)/g' "`dirname "$0"`/../exports/web/airships.js"
