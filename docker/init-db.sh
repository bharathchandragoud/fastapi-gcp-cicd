#!/bin/bash
psql -U user -d commerce_ai -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";'
