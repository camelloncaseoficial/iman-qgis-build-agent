# Processo descartavel que falha de verdade, para o crash handler instalado montar a pilha (patch de 2026-10-29 da
# fatia 047, P3). Rodado pelo Test-CrashStack.ps1 com o Python da arvore instalada: python -I crash_target.py
# <arquivo de info> <caminho de simbolos>.
# Uma thread nativa comeca no strlen do msvcrt com argumento nulo e le o endereco 0. O filtro de excecao nao tratada
# grava o arquivo de info no formato do QgsCrashHandler::handleCrash (PID, thread, ponteiro das excecoes, caminho de
# simbolos, log do Python, argumentos, versao) e segura a thread viva: o crash handler le a memoria e a pilha deste
# processo enquanto ele espera. Quem abre e fecha este processo e o teste, pelo PID.
import ctypes
import os
import sys
import time
from ctypes import wintypes

info_path, symbol_path = sys.argv[1], sys.argv[2]
kernel32 = ctypes.WinDLL("kernel32")
kernel32.GetCurrentThreadId.restype = wintypes.DWORD
kernel32.SetUnhandledExceptionFilter.argtypes = [ctypes.c_void_p]
kernel32.SetUnhandledExceptionFilter.restype = ctypes.c_void_p
kernel32.CreateThread.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_void_p, ctypes.c_void_p, wintypes.DWORD, ctypes.c_void_p]
kernel32.CreateThread.restype = wintypes.HANDLE
FILTER = ctypes.WINFUNCTYPE(ctypes.c_long, ctypes.c_void_p)


def on_crash(pointers):
    lines = [
        str(os.getpid()),
        str(kernel32.GetCurrentThreadId()),
        "0x%016x" % pointers,
        symbol_path,
        "",
        "",
        "Relatorio do teste P3 do patch de 2026-10-29 da fatia 047: falha provocada num processo descartavel",
    ]
    tmp = info_path + ".part"
    with open(tmp, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines) + "\n")
    os.replace(tmp, info_path)
    while True:
        time.sleep(1)


crash_filter = FILTER(on_crash)
kernel32.SetUnhandledExceptionFilter(ctypes.cast(crash_filter, ctypes.c_void_p))
strlen = ctypes.cast(ctypes.CDLL("msvcrt").strlen, ctypes.c_void_p)
kernel32.CreateThread(None, 0, strlen, None, 0, None)
while True:
    time.sleep(1)
