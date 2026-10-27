# Captura de janelas de outro processo (dot-source: . "$PSScriptRoot\WindowCapture.ps1"), para as superficies que
# nao sao widgets do QGIS em execucao: splash real, crash handler e caixa de erro de carga (briefing 044, A5, A8, A9).
# So le a tela e manda WM_CLOSE para a janela capturada; nao clica em nada.

Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes, System.Drawing
if (-not ('ImanWindowCapture' -as [type])) {
  Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;

public static class ImanWindowCapture
{
    delegate bool EnumProc(IntPtr hwnd, IntPtr lParam);
    [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc cb, IntPtr lParam);
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint pid);
    [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr hwnd);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr hwnd, StringBuilder s, int n);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetClassName(IntPtr hwnd, StringBuilder s, int n);
    [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr hwnd, out RECT r);
    [DllImport("user32.dll")] static extern bool PrintWindow(IntPtr hwnd, IntPtr hdc, uint flags);
    [DllImport("user32.dll")] static extern bool PostMessage(IntPtr hwnd, uint msg, IntPtr w, IntPtr l);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }

    public static List<IntPtr> Windows(int pid)
    {
        var list = new List<IntPtr>();
        EnumWindows((h, l) => {
            uint p; GetWindowThreadProcessId(h, out p);
            if (p == (uint)pid && IsWindowVisible(h)) list.Add(h);
            return true;
        }, IntPtr.Zero);
        return list;
    }
    public static string Title(IntPtr h) { var s = new StringBuilder(512); GetWindowText(h, s, 512); return s.ToString(); }
    public static string ClassName(IntPtr h) { var s = new StringBuilder(256); GetClassName(h, s, 256); return s.ToString(); }
    public static int[] Size(IntPtr h) { PhysicalCoordinates(); RECT r; GetWindowRect(h, out r); return new[] { r.Right - r.Left, r.Bottom - r.Top }; }
    [DllImport("user32.dll")] static extern IntPtr GetWindowDC(IntPtr hwnd);
    [DllImport("user32.dll")] static extern int ReleaseDC(IntPtr hwnd, IntPtr hdc);
    [DllImport("gdi32.dll")] static extern IntPtr CreateCompatibleDC(IntPtr hdc);
    [DllImport("gdi32.dll")] static extern IntPtr CreateCompatibleBitmap(IntPtr hdc, int w, int h);
    [DllImport("gdi32.dll")] static extern IntPtr SelectObject(IntPtr hdc, IntPtr obj);
    [DllImport("gdi32.dll")] static extern bool DeleteDC(IntPtr hdc);
    [DllImport("gdi32.dll")] public static extern bool DeleteObject(IntPtr obj);

    // PrintWindow num bitmap GDI; quem chama salva (System.Drawing) e libera com DeleteObject
    public static IntPtr Grab(IntPtr h)
    {
        PhysicalCoordinates();
        RECT r; GetWindowRect(h, out r);
        int w = r.Right - r.Left, ht = r.Bottom - r.Top;
        if (w <= 0 || ht <= 0) return IntPtr.Zero;
        IntPtr wdc = GetWindowDC(h);
        IntPtr mdc = CreateCompatibleDC(wdc);
        IntPtr bmp = CreateCompatibleBitmap(wdc, w, ht);
        IntPtr old = SelectObject(mdc, bmp);
        bool ok = PrintWindow(h, mdc, 2);
        SelectObject(mdc, old);
        DeleteDC(mdc);
        ReleaseDC(h, wdc);
        if (!ok) { DeleteObject(bmp); return IntPtr.Zero; }
        return bmp;
    }
    [DllImport("user32.dll")] static extern IntPtr SetThreadDpiAwarenessContext(IntPtr ctx);
    // coordenadas reais de tela (sem a escala do Windows): DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2
    static void PhysicalCoordinates() { SetThreadDpiAwarenessContext(new IntPtr(-4)); }
    public static void Close(IntPtr h) { PostMessage(h, 0x0010, IntPtr.Zero, IntPtr.Zero); }
}
'@
}

# Espera ate $TimeoutSeconds por uma janela visivel do processo que passe no filtro; devolve o handle ou $null.
function Wait-ProcessWindow([int] $ProcessId, [scriptblock] $Filter, [int] $TimeoutSeconds = 60) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    foreach ($h in [ImanWindowCapture]::Windows($ProcessId)) { if (& $Filter $h) { return $h } }
    Start-Sleep -Milliseconds 200
  }
  $null
}

# Textos que a janela expoe pela acessibilidade (UI Automation): rotulos, botoes, campos.
function Get-WindowTexts([IntPtr] $Handle) {
  $root = [System.Windows.Automation.AutomationElement]::FromHandle($Handle)
  $all = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)
  @($all | ForEach-Object { $_.Current.Name } | Where-Object { $_ })
}

# Salva a janela em PNG (PrintWindow com PW_RENDERFULLCONTENT); devolve $true se gravou.
function Save-WindowImage([IntPtr] $Handle, [string] $Path) {
  $bmp = [ImanWindowCapture]::Grab($Handle)
  if ($bmp -eq [IntPtr]::Zero) { return $false }
  try {
    $img = [System.Drawing.Image]::FromHbitmap($bmp)
    $img.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $img.Dispose()
    $true
  } finally { [void][ImanWindowCapture]::DeleteObject($bmp) }
}
