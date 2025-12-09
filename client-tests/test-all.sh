#!/bin/bash

echo "spectrum ssl bug - full test suite"
echo "==================================="
echo ""

if [ "$EUID" -eq 0 ]; then
    echo "running as root - full test mode"
    echo ""

    ./run-tests.sh
    echo ""
    echo "-----------------------------------"
    echo ""
    ./capture-packets.sh
else
    echo "running without root - basic tests only"
    echo "for packet captures, run: sudo ./test-all.sh"
    echo ""

    ./run-tests.sh
fi

echo ""
echo "all tests complete"
echo "check the results/ folder for output"
