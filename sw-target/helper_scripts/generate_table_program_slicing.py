#!/usr/bin/env python3

import argparse
import sys

def main(args):
    args = parse_args(args)
    with open(args.output_file, 'w') as file:
        to_write = str()

        for i in range(2, args.number_rules+2):
            to_write += f"(0xa{i:06x}, 0x11, 0x5208): modify_and_forward_pkt(FORWARD_A, 31000);\n"

        file.write(to_write)


def parse_args(args):
    parser = argparse.ArgumentParser(
        description='Generate table file')
    parser.add_argument('output_file', type=str, help='path of generated file')
    parser.add_argument('number_rules', type=int, help='number of generated rules')
    args = parser.parse_args(args[1:])
    return args


if __name__ == '__main__':
    main(sys.argv)
