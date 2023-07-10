#!/bin/bash

# Run this transaction several times to increment the block height
flow transactions send ./transactions/tick_tock.cdc

flow transactions send ./transactions/tick_tock.cdc