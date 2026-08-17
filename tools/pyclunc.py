#!/usr/bin/env python3
import argparse
import ipaddress
import os
import select
import socket
import struct
import sys
import termios
import time
import tty

BROADCAST_PORT = 4446
CONSOLE_PORT = 6666


def mac_bytes(text):
    if text is None:
        return b"\x00" * 6
    parts = text.replace('-', ':').split(':')
    if len(parts) != 6:
        raise SystemExit('bad mac')
    return bytes(int(p, 16) for p in parts)


def tlv(tag, value):
    return tag.encode('ascii').ljust(4, b'\x00') + struct.pack('!I', len(value)) + value


def field(tag, kind, value):
    return tlv(tag, tlv(kind, value))


def lump_packet(nas_ip, dest_mac=None):
    ip_raw = int(ipaddress.IPv4Address(nas_ip)).to_bytes(4, 'big')
    mac_d = b"\x00\x00" + mac_bytes(dest_mac)
    mac_s = b"\x00" * 8
    body = b''.join([
        field('IPS', 'IP@', ip_raw),
        field('MACD', 'MAC@', mac_d),
        field('MACS', 'MAC@', mac_s),
    ])
    return tlv('LUMP', body)


def main():
    ap = argparse.ArgumentParser(description='Small CLUNC compatible client for LaCie U-Boot NetConsole')
    ap.add_argument('-i', '--ip', required=True, help='IP for the NAS in U-Boot')
    ap.add_argument('-m', '--mac', default=None, help='NAS MAC address')
    ap.add_argument('-b', '--broadcast', default='255.255.255.255')
    ap.add_argument('--timeout', type=float, default=90.0)
    args = ap.parse_args()

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    sock.bind(('', CONSOLE_PORT))
    sock.setblocking(False)

    pkt = lump_packet(args.ip, args.mac)
    end = time.time() + args.timeout
    old = termios.tcgetattr(sys.stdin)
    got_console = False

    try:
        tty.setraw(sys.stdin.fileno())
        next_lump = 0.0
        while True:
            now = time.time()
            if not got_console and now >= next_lump:
                sock.sendto(pkt, (args.broadcast, BROADCAST_PORT))
                sock.sendto(b'\x03', (args.ip, CONSOLE_PORT))
                next_lump = now + 0.5
            if not got_console and now > end:
                sys.stderr.write('\ntimeout waiting for netconsole\n')
                return 1
            r, _, _ = select.select([sock, sys.stdin], [], [], 0.1)
            for item in r:
                if item is sock:
                    data, addr = sock.recvfrom(65535)
                    if data:
                        got_console = True
                        os.write(sys.stdout.fileno(), data)
                else:
                    data = os.read(sys.stdin.fileno(), 1024)
                    if data:
                        sock.sendto(data, (args.ip, CONSOLE_PORT))
    finally:
        termios.tcsetattr(sys.stdin, termios.TCSADRAIN, old)


if __name__ == '__main__':
    raise SystemExit(main())
