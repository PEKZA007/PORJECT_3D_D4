Add-Type -AssemblyName System.Drawing
$taskPages = Get-Content -LiteralPath 'tmp/pdfs/thai-slides/pages.json' -Raw -Encoding UTF8 | ConvertFrom-Json
$taskIndex = 0
foreach ($taskPage in $taskPages) {
    $taskIndex++
    $taskBitmap = New-Object System.Drawing.Bitmap(1600,1000)
    $taskGraphics = [System.Drawing.Graphics]::FromImage($taskBitmap)
    $taskGraphics.Clear([System.Drawing.Color]::White)
    $taskGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $taskGraphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    foreach ($taskItem in $taskPage) {
        $taskColor = [System.Drawing.ColorTranslator]::FromHtml($taskItem.color)
        $taskPen = New-Object System.Drawing.Pen($taskColor, [single]$taskItem.width)
        if ($taskItem.kind -eq 'text') {
            $taskStyle = [System.Drawing.FontStyle]::Regular
            if ($taskItem.bold) { $taskStyle = [System.Drawing.FontStyle]::Bold }
            $taskFont = New-Object System.Drawing.Font('Tahoma', [single]$taskItem.size, $taskStyle, [System.Drawing.GraphicsUnit]::Pixel)
            $taskBrush = New-Object System.Drawing.SolidBrush($taskColor)
            $taskGraphics.DrawString([string]$taskItem.text, $taskFont, $taskBrush, [single]$taskItem.x, [single]$taskItem.y)
            $taskFont.Dispose(); $taskBrush.Dispose()
        } elseif ($taskItem.kind -eq 'line') {
            $taskGraphics.DrawLine($taskPen, [single]$taskItem.x, [single]$taskItem.y, [single]$taskItem.w, [single]$taskItem.h)
        } else {
            $taskRectangle = New-Object System.Drawing.RectangleF([single]$taskItem.x,[single]$taskItem.y,[single]$taskItem.w,[single]$taskItem.h)
            if ($taskItem.fill) {
                $taskBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml($taskItem.fill))
                if ($taskItem.kind -eq 'ellipse') { $taskGraphics.FillEllipse($taskBrush,$taskRectangle) } else { $taskGraphics.FillRectangle($taskBrush,$taskRectangle) }
                $taskBrush.Dispose()
            }
            if ($taskItem.kind -eq 'ellipse') { $taskGraphics.DrawEllipse($taskPen,$taskRectangle) } else { $taskGraphics.DrawRectangle($taskPen,$taskRectangle.X,$taskRectangle.Y,$taskRectangle.Width,$taskRectangle.Height) }
        }
        $taskPen.Dispose()
    }
    $taskBitmap.Save((Join-Path (Get-Location) ('tmp/pdfs/thai-slides/page-{0:D2}.png' -f $taskIndex)),[System.Drawing.Imaging.ImageFormat]::Png)
    $taskGraphics.Dispose(); $taskBitmap.Dispose()
}
Write-Output "Rendered $taskIndex slides"
