#!/usr/bin/env python3
"""stdio <-> TCP proxy for Godot's language server when nvim runs in WSL and
Godot runs on Windows. Translates file URIs between /mnt/c/... (WSL) and
C:/... (Windows) in both directions, fixing Content-Length framing."""
import re
import socket
import sys
import threading

host, port = sys.argv[1], int(sys.argv[2])

TO_WIN = [(re.compile(rb'file:///mnt/([a-zA-Z])/'), lambda m: b'file:///' + m.group(1).upper() + b':/')]
TO_WSL = [(re.compile(rb'file:///([a-zA-Z])(?::|%3[aA])/'), lambda m: b'file:///mnt/' + m.group(1).lower() + b'/')]


def rewrite(body, rules):
    for pat, rep in rules:
        body = pat.sub(rep, body)
    return body


def read_msg(read):
    length = None
    while True:
        line = read.readline()
        if not line:
            return None
        if line in (b'\r\n', b'\n'):
            break
        if line.lower().startswith(b'content-length:'):
            length = int(line.split(b':', 1)[1])
    if length is None:
        return None
    body = b''
    while len(body) < length:
        chunk = read.read(length - len(body))
        if not chunk:
            return None
        body += chunk
    return body


def pump(src, dst, rules):
    while True:
        body = read_msg(src)
        if body is None:
            break
        body = rewrite(body, rules)
        dst.write(b'Content-Length: %d\r\n\r\n' % len(body) + body)
        dst.flush()


sock = socket.create_connection((host, port))
sock_r, sock_w = sock.makefile('rb'), sock.makefile('wb')
t = threading.Thread(target=pump, args=(sock_r, sys.stdout.buffer, TO_WSL), daemon=True)
t.start()
pump(sys.stdin.buffer, sock_w, TO_WIN)
sock.close()
