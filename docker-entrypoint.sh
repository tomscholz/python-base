#!/bin/bash
set -e

source "$(poetry env info --path)/bin/activate"

exec "$@"