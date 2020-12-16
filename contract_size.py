#!/usr/bin/env python3

import json
import sys

def process(f):
    data = json.load(f)
    bytecode = data["bytecode"]
    deployed = data["deployedBytecode"]

    bt = bytes.fromhex(bytecode[2:].rstrip())
    dbt = bytes.fromhex(deployed[2:].rstrip())

    print(len(bt))
    print("Deployed ", len(dbt))

def main(fname):
    print(fname)
    with open(fname, "r") as f:
        process(f)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"usage: {sys.argv[0]} contract1.json [contract2.json ...]")
    else:
        for c in sys.argv[1:]:
            main(c)
