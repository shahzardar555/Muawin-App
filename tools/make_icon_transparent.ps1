param(
  [string]$InputPath = "C:\Users\Admin\muawin_app\assets\muawin_icon_raw.png",
  [string]$OutputPath = "C:\Users\Admin\muawin_app\assets\muawin_icon.png"
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$code = @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class MuawinIconBgToAlpha
{
  private static int Dist2(byte r, byte g, byte b, Color c)
  {
    int dr = (int)r - (int)c.R;
    int dg = (int)g - (int)c.G;
    int db = (int)b - (int)c.B;
    return (dr * dr) + (dg * dg) + (db * db);
  }

  public static string Convert(string inputPath, string outputPath, int threshold)
  {
    Bitmap src0 = new Bitmap(inputPath);
    Bitmap src = new Bitmap(src0.Width, src0.Height, PixelFormat.Format32bppArgb);
    Graphics gr = Graphics.FromImage(src);
    gr.DrawImage(src0, 0, 0, src0.Width, src0.Height);
    gr.Dispose();
    src0.Dispose();

    // Sample likely background colors from corners + a few offsets.
    Point[] samples = new Point[] {
      new Point(0,0),
      new Point(src.Width-1,0),
      new Point(0,src.Height-1),
      new Point(src.Width-1,src.Height-1),
      new Point(8,8),
      new Point(src.Width-9,8),
      new Point(8,src.Height-9),
      new Point(src.Width-9,src.Height-9),
    };

    Dictionary<int, Color> bgMap = new Dictionary<int, Color>();
    foreach (Point pt in samples)
    {
      Color c = src.GetPixel(pt.X, pt.Y);
      int key = (c.R << 16) | (c.G << 8) | c.B;
      if (bgMap.ContainsKey(key)) bgMap[key] = c;
      else bgMap.Add(key, c);
    }
    List<Color> bg = new List<Color>(bgMap.Values);

    int thr2 = threshold * threshold;
    int changed = 0;

    var rect = new Rectangle(0, 0, src.Width, src.Height);
    var data = src.LockBits(rect, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
    try
    {
      int bytes = Math.Abs(data.Stride) * data.Height;
      byte[] buffer = new byte[bytes];
      Marshal.Copy(data.Scan0, buffer, 0, bytes);

      // BGRA order
      for (int y = 0; y < data.Height; y++)
      {
        int row = y * data.Stride;
        for (int x = 0; x < data.Width; x++)
        {
          int i = row + (x * 4);
          byte b = buffer[i + 0];
          byte g = buffer[i + 1];
          byte r = buffer[i + 2];
          byte a = buffer[i + 3];

          // Skip already transparent pixels.
          if (a == 0) continue;

          for (int k = 0; k < bg.Count; k++)
          {
            if (Dist2(r, g, b, bg[k]) <= thr2)
            {
              buffer[i + 3] = 0; // alpha
              changed++;
              break;
            }
          }
        }
      }

      Marshal.Copy(buffer, 0, data.Scan0, bytes);
    }
    finally
    {
      src.UnlockBits(data);
    }

    src.Save(outputPath, ImageFormat.Png);
    byte cornerAlpha = src.GetPixel(0, 0).A;

    src.Dispose();
    return "changedPixels=" + changed + " cornerAlpha=" + cornerAlpha + " output=" + outputPath;
  }
}
"@

Add-Type -TypeDefinition $code -ReferencedAssemblies "System.Drawing.dll","System.dll" -IgnoreWarnings

$threshold = 22
$result = [MuawinIconBgToAlpha]::Convert($InputPath, $OutputPath, $threshold)
Write-Output $result

