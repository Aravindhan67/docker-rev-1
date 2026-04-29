Add-Type -AssemblyName System.Drawing

$width = 1600
$height = 900
$outputPath = Join-Path $PSScriptRoot "student-problem-statement-diagram.png"

$bitmap = New-Object System.Drawing.Bitmap $width, $height
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$graphics.Clear([System.Drawing.Color]::White)

function New-RoundedRectPath {
    param(
        [float]$X,
        [float]$Y,
        [float]$Width,
        [float]$Height,
        [float]$Radius
    )

    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $diameter = $Radius * 2
    $path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
    $path.AddArc($X + $Width - $diameter, $Y, $diameter, $diameter, 270, 90)
    $path.AddArc($X + $Width - $diameter, $Y + $Height - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($X, $Y + $Height - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

function Draw-CenteredText {
    param(
        [System.Drawing.Graphics]$Graphics,
        [string]$Text,
        [System.Drawing.Font]$Font,
        [System.Drawing.Brush]$Brush,
        [float]$X,
        [float]$Y,
        [float]$Width,
        [float]$Height
    )

    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    $rect = New-Object System.Drawing.RectangleF($X, $Y, $Width, $Height)
    $Graphics.DrawString($Text, $Font, $Brush, $rect, $format)
    $format.Dispose()
}

function Draw-TopAlignedText {
    param(
        [System.Drawing.Graphics]$Graphics,
        [string]$Text,
        [System.Drawing.Font]$Font,
        [System.Drawing.Brush]$Brush,
        [float]$X,
        [float]$Y,
        [float]$Width,
        [float]$Height
    )

    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Near
    $rect = New-Object System.Drawing.RectangleF($X, $Y, $Width, $Height)
    $Graphics.DrawString($Text, $Font, $Brush, $rect, $format)
    $format.Dispose()
}

function Draw-Arrow {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Pen]$Pen,
        [float]$X1,
        [float]$Y1,
        [float]$X2,
        [float]$Y2
    )

    $Graphics.DrawLine($Pen, $X1, $Y1, $X2, $Y2)
    $angle = [Math]::Atan2($Y2 - $Y1, $X2 - $X1)
    $arrowLength = 16
    $arrowWidth = [Math]::PI / 7
    $p1 = New-Object System.Drawing.PointF -ArgumentList `
        ($X2 - $arrowLength * [Math]::Cos($angle - $arrowWidth)), `
        ($Y2 - $arrowLength * [Math]::Sin($angle - $arrowWidth))
    $p2 = New-Object System.Drawing.PointF -ArgumentList `
        ($X2 - $arrowLength * [Math]::Cos($angle + $arrowWidth)), `
        ($Y2 - $arrowLength * [Math]::Sin($angle + $arrowWidth))
    [System.Drawing.PointF[]]$triangle = @(
            (New-Object System.Drawing.PointF -ArgumentList $X2, $Y2),
            $p1,
            $p2
        )
    $Graphics.FillPolygon([System.Drawing.Brushes]::Black, $triangle)
}

function Draw-UserIcon {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$X,
        [float]$Y
    )

    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(40, 48, 60))
    $Graphics.FillEllipse($brush, $X + 26, $Y, 42, 42)
    $Graphics.FillEllipse($brush, $X + 10, $Y + 48, 74, 88)
    $brush.Dispose()
}

function Draw-NodeIcon {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$CenterX,
        [float]$CenterY
    )

    [System.Drawing.PointF[]]$points = @(
        (New-Object System.Drawing.PointF -ArgumentList $CenterX, ($CenterY - 50)),
        (New-Object System.Drawing.PointF -ArgumentList ($CenterX + 42), ($CenterY - 25)),
        (New-Object System.Drawing.PointF -ArgumentList ($CenterX + 42), ($CenterY + 25)),
        (New-Object System.Drawing.PointF -ArgumentList $CenterX, ($CenterY + 50)),
        (New-Object System.Drawing.PointF -ArgumentList ($CenterX - 42), ($CenterY + 25)),
        (New-Object System.Drawing.PointF -ArgumentList ($CenterX - 42), ($CenterY - 25))
    )
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(112, 190, 72), 6)
    $Graphics.DrawPolygon($pen, $points)
    Draw-CenteredText -Graphics $Graphics -Text "JS" -Font $script:iconFont -Brush ([System.Drawing.Brushes]::Black) -X ($CenterX - 34) -Y ($CenterY - 24) -Width 68 -Height 48
    $pen.Dispose()
}

function Draw-DockerIcon {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$X,
        [float]$Y
    )

    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(34, 120, 212))
    for ($row = 0; $row -lt 3; $row++) {
        for ($col = 0; $col -lt (4 - $row); $col++) {
            $Graphics.FillRectangle($brush, $X + ($col * 20) + ($row * 10), $Y + ($row * 20), 16, 16)
        }
    }
    $Graphics.FillEllipse($brush, $X + 82, $Y + 42, 18, 12)
    $Graphics.FillPie($brush, $X + 92, $Y + 38, 36, 22, 330, 180)
    $brush.Dispose()
}

function Draw-KubeBadge {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$X,
        [float]$Y
    )

    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(49, 107, 232))
    [System.Drawing.PointF[]]$points = @(
        (New-Object System.Drawing.PointF -ArgumentList ($X + 24), $Y),
        (New-Object System.Drawing.PointF -ArgumentList ($X + 48), ($Y + 14)),
        (New-Object System.Drawing.PointF -ArgumentList ($X + 48), ($Y + 42)),
        (New-Object System.Drawing.PointF -ArgumentList ($X + 24), ($Y + 56)),
        (New-Object System.Drawing.PointF -ArgumentList $X, ($Y + 42)),
        (New-Object System.Drawing.PointF -ArgumentList $X, ($Y + 14))
    )
    $Graphics.FillPolygon($brush, $points)
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 3)
    $Graphics.DrawEllipse($pen, $X + 12, $Y + 12, 24, 24)
    $Graphics.DrawLine($pen, $X + 24, $Y + 6, $X + 24, $Y + 18)
    $Graphics.DrawLine($pen, $X + 10, $Y + 30, $X + 18, $Y + 24)
    $Graphics.DrawLine($pen, $X + 38, $Y + 24, $X + 30, $Y + 30)
    $pen.Dispose()
    $brush.Dispose()
}

function Draw-DeploymentIcon {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$X,
        [float]$Y
    )

    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(48, 101, 221))
    [System.Drawing.PointF[]]$hex = @(
        (New-Object System.Drawing.PointF -ArgumentList ($X + 50), $Y),
        (New-Object System.Drawing.PointF -ArgumentList ($X + 94), ($Y + 26)),
        (New-Object System.Drawing.PointF -ArgumentList ($X + 94), ($Y + 78)),
        (New-Object System.Drawing.PointF -ArgumentList ($X + 50), ($Y + 104)),
        (New-Object System.Drawing.PointF -ArgumentList ($X + 6), ($Y + 78)),
        (New-Object System.Drawing.PointF -ArgumentList ($X + 6), ($Y + 26))
    )
    $Graphics.FillPolygon($brush, $hex)
    $cubeBrush = [System.Drawing.Brushes]::White
    $cubePen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 3)
    $Graphics.DrawRectangle($cubePen, $X + 25, $Y + 34, 16, 16)
    $Graphics.DrawRectangle($cubePen, $X + 47, $Y + 24, 16, 16)
    $Graphics.DrawRectangle($cubePen, $X + 52, $Y + 52, 16, 16)
    $Graphics.DrawRectangle($cubePen, $X + 28, $Y + 58, 16, 16)
    $cubePen.Dispose()
    $brush.Dispose()
}

function Draw-ServiceIcon {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$X,
        [float]$Y
    )

    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(48, 101, 221))
    [System.Drawing.PointF[]]$hex = @(
        (New-Object System.Drawing.PointF -ArgumentList ($X + 50), $Y),
        (New-Object System.Drawing.PointF -ArgumentList ($X + 94), ($Y + 26)),
        (New-Object System.Drawing.PointF -ArgumentList ($X + 94), ($Y + 78)),
        (New-Object System.Drawing.PointF -ArgumentList ($X + 50), ($Y + 104)),
        (New-Object System.Drawing.PointF -ArgumentList ($X + 6), ($Y + 78)),
        (New-Object System.Drawing.PointF -ArgumentList ($X + 6), ($Y + 26))
    )
    $Graphics.FillPolygon($brush, $hex)
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 4)
    $Graphics.DrawLine($pen, $X + 50, $Y + 22, $X + 50, $Y + 76)
    $Graphics.DrawLine($pen, $X + 30, $Y + 52, $X + 70, $Y + 52)
    $Graphics.DrawLine($pen, $X + 30, $Y + 78, $X + 70, $Y + 78)
    $Graphics.FillRectangle([System.Drawing.Brushes]::White, $X + 44, $Y + 14, 12, 12)
    $Graphics.FillRectangle([System.Drawing.Brushes]::White, $X + 24, $Y + 46, 12, 12)
    $Graphics.FillRectangle([System.Drawing.Brushes]::White, $X + 64, $Y + 46, 12, 12)
    $Graphics.FillRectangle([System.Drawing.Brushes]::White, $X + 24, $Y + 72, 12, 12)
    $Graphics.FillRectangle([System.Drawing.Brushes]::White, $X + 64, $Y + 72, 12, 12)
    $pen.Dispose()
    $brush.Dispose()
}

function Draw-PodsIcon {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$X,
        [float]$Y
    )

    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(48, 101, 221), 4)
    foreach ($offset in @(
            @{ X = 0; Y = 28 },
            @{ X = 38; Y = 0 },
            @{ X = 76; Y = 28 }
        )) {
        $cx = $X + $offset.X
        $cy = $Y + $offset.Y
        [System.Drawing.PointF[]]$points = @(
            (New-Object System.Drawing.PointF -ArgumentList ($cx + 24), $cy),
            (New-Object System.Drawing.PointF -ArgumentList ($cx + 48), ($cy + 14)),
            (New-Object System.Drawing.PointF -ArgumentList ($cx + 48), ($cy + 42)),
            (New-Object System.Drawing.PointF -ArgumentList ($cx + 24), ($cy + 56)),
            (New-Object System.Drawing.PointF -ArgumentList $cx, ($cy + 42)),
            (New-Object System.Drawing.PointF -ArgumentList $cx, ($cy + 14))
        )
        $Graphics.DrawPolygon($pen, $points)
    }
    $pen.Dispose()
}

function Draw-HPAIcon {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$X,
        [float]$Y
    )

    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(234, 152, 23))
    $Graphics.FillRectangle($brush, $X + 8, $Y + 52, 18, 32)
    $Graphics.FillRectangle($brush, $X + 36, $Y + 38, 18, 46)
    $Graphics.FillRectangle($brush, $X + 64, $Y + 22, 18, 62)
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(234, 152, 23), 5)
    $Graphics.DrawLine($pen, $X + 12, $Y + 70, $X + 44, $Y + 44)
    $Graphics.DrawLine($pen, $X + 44, $Y + 44, $X + 74, $Y + 24)
    Draw-Arrow -Graphics $Graphics -Pen $pen -X1 ($X + 74) -Y1 ($Y + 24) -X2 ($X + 94) -Y2 ($Y + 10)
    $pen.Dispose()
    $brush.Dispose()
}

function Draw-PrometheusIcon {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$CenterX,
        [float]$CenterY
    )

    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(241, 102, 41))
    $Graphics.FillEllipse($brush, $CenterX - 40, $CenterY - 46, 80, 80)
    [System.Drawing.PointF[]]$flame = @(
        (New-Object System.Drawing.PointF -ArgumentList $CenterX, ($CenterY - 28)),
        (New-Object System.Drawing.PointF -ArgumentList ($CenterX + 16), ($CenterY - 4)),
        (New-Object System.Drawing.PointF -ArgumentList ($CenterX + 8), ($CenterY + 24)),
        (New-Object System.Drawing.PointF -ArgumentList ($CenterX - 8), ($CenterY + 20)),
        (New-Object System.Drawing.PointF -ArgumentList ($CenterX - 18), ($CenterY - 4))
    )
    $Graphics.FillPolygon([System.Drawing.Brushes]::White, $flame)
    $Graphics.FillRectangle([System.Drawing.Brushes]::White, $CenterX - 26, $CenterY + 38, 52, 8)
    $brush.Dispose()
}

function Draw-GrafanaIcon {
    param(
        [System.Drawing.Graphics]$Graphics,
        [float]$CenterX,
        [float]$CenterY
    )

    $orange = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(247, 132, 32))
    $blue = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(27, 122, 205))
    for ($i = 0; $i -lt 8; $i++) {
        $angle = $i * [Math]::PI / 4
        $px = $CenterX + [Math]::Cos($angle) * 34
        $py = $CenterY + [Math]::Sin($angle) * 34
        $Graphics.FillEllipse($orange, $px - 10, $py - 10, 20, 20)
    }
    $Graphics.FillEllipse($orange, $CenterX - 26, $CenterY - 26, 52, 52)
    $Graphics.FillEllipse($blue, $CenterX - 6, $CenterY - 6, 22, 22)
    $orange.Dispose()
    $blue.Dispose()
}

$linePen = New-Object System.Drawing.Pen([System.Drawing.Color]::Black, 4)
$boxFill = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$textBrush = [System.Drawing.Brushes]::Black

$titleFont = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$labelFont = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Regular)
$smallFont = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
$script:iconFont = New-Object System.Drawing.Font("Segoe UI", 22, [System.Drawing.FontStyle]::Bold)

# User block
Draw-UserIcon -Graphics $graphics -X 28 -Y 104
Draw-CenteredText -Graphics $graphics -Text "User`n(Browser)" -Font $labelFont -Brush $textBrush -X 10 -Y 240 -Width 120 -Height 70

# Application box
$appX = 180; $appY = 60; $appW = 260; $appH = 320
$appPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(109, 183, 89), 4)
$path = New-RoundedRectPath -X $appX -Y $appY -Width $appW -Height $appH -Radius 18
$graphics.FillPath($boxFill, $path)
$graphics.DrawPath($appPen, $path)
Draw-TopAlignedText -Graphics $graphics -Text "Student Result`nApplication" -Font $titleFont -Brush $textBrush -X $appX -Y ($appY + 24) -Width $appW -Height 80
Draw-NodeIcon -Graphics $graphics -CenterX ($appX + $appW / 2) -CenterY ($appY + 155)
Draw-CenteredText -Graphics $graphics -Text "Node.js App" -Font $labelFont -Brush $textBrush -X $appX -Y ($appY + 232) -Width $appW -Height 50

# Docker box
$dockX = 500; $dockY = 60; $dockW = 220; $dockH = 320
$dockPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(81, 136, 231), 4)
$path2 = New-RoundedRectPath -X $dockX -Y $dockY -Width $dockW -Height $dockH -Radius 18
$graphics.FillPath($boxFill, $path2)
$graphics.DrawPath($dockPen, $path2)
Draw-TopAlignedText -Graphics $graphics -Text "Docker" -Font $titleFont -Brush $textBrush -X $dockX -Y ($dockY + 24) -Width $dockW -Height 50
Draw-DockerIcon -Graphics $graphics -X ($dockX + 54) -Y ($dockY + 106)
Draw-CenteredText -Graphics $graphics -Text "Containerized`nApplication" -Font $labelFont -Brush $textBrush -X $dockX -Y ($dockY + 212) -Width $dockW -Height 70

# Kubernetes cluster box
$clusterX = 790; $clusterY = 50; $clusterW = 700; $clusterH = 350
$clusterPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(81, 136, 231), 4)
$path3 = New-RoundedRectPath -X $clusterX -Y $clusterY -Width $clusterW -Height $clusterH -Radius 18
$graphics.FillPath($boxFill, $path3)
$graphics.DrawPath($clusterPen, $path3)
Draw-KubeBadge -Graphics $graphics -X ($clusterX + 30) -Y ($clusterY + 26)
Draw-CenteredText -Graphics $graphics -Text "Kubernetes Cluster" -Font $titleFont -Brush $textBrush -X ($clusterX + 70) -Y ($clusterY + 20) -Width 280 -Height 60

Draw-DeploymentIcon -Graphics $graphics -X ($clusterX + 50) -Y ($clusterY + 105)
Draw-ServiceIcon -Graphics $graphics -X ($clusterX + 265) -Y ($clusterY + 105)
Draw-PodsIcon -Graphics $graphics -X ($clusterX + 510) -Y ($clusterY + 128)

Draw-CenteredText -Graphics $graphics -Text "Deployment`n(Pods)" -Font $labelFont -Brush $textBrush -X ($clusterX + 20) -Y ($clusterY + 220) -Width 160 -Height 76
Draw-CenteredText -Graphics $graphics -Text "Service`n(Load Balancer)" -Font $labelFont -Brush $textBrush -X ($clusterX + 230) -Y ($clusterY + 220) -Width 170 -Height 76
Draw-CenteredText -Graphics $graphics -Text "Pods`n(Running App)" -Font $labelFont -Brush $textBrush -X ($clusterX + 495) -Y ($clusterY + 220) -Width 150 -Height 76

# Top arrows
Draw-Arrow -Graphics $graphics -Pen $linePen -X1 120 -Y1 220 -X2 170 -Y2 220
Draw-Arrow -Graphics $graphics -Pen $linePen -X1 ($appX + $appW) -Y1 220 -X2 ($dockX - 10) -Y2 220
Draw-Arrow -Graphics $graphics -Pen $linePen -X1 ($dockX + $dockW) -Y1 220 -X2 ($clusterX - 10) -Y2 220
Draw-Arrow -Graphics $graphics -Pen $linePen -X1 ($clusterX + 170) -Y1 195 -X2 ($clusterX + 255) -Y2 195
Draw-Arrow -Graphics $graphics -Pen $linePen -X1 ($clusterX + 390) -Y1 195 -X2 ($clusterX + 500) -Y2 195

# Bottom boxes
$bottomY = 560
$smallW = 260
$smallH = 240
$hpaX = 300
$promX = 660
$grafX = 1040

foreach ($box in @(
        @{ X = $hpaX; Color = [System.Drawing.Color]::FromArgb(243, 167, 56); Title = "HPA"; Subtitle = "(Auto Scaling)" },
        @{ X = $promX; Color = [System.Drawing.Color]::FromArgb(151, 106, 230); Title = "Prometheus"; Subtitle = "" },
        @{ X = $grafX; Color = [System.Drawing.Color]::FromArgb(109, 183, 89); Title = "Grafana"; Subtitle = "" }
    )) {
    $pen = New-Object System.Drawing.Pen($box.Color, 4)
    $p = New-RoundedRectPath -X $box.X -Y $bottomY -Width $smallW -Height $smallH -Radius 18
    $graphics.FillPath($boxFill, $p)
    $graphics.DrawPath($pen, $p)
    $text = if ($box.Subtitle) { "$($box.Title)`n$($box.Subtitle)" } else { $box.Title }
    Draw-TopAlignedText -Graphics $graphics -Text $text -Font $titleFont -Brush $textBrush -X $box.X -Y ($bottomY + 24) -Width $smallW -Height 60
    $pen.Dispose()
    $p.Dispose()
}

Draw-HPAIcon -Graphics $graphics -X ($hpaX + 80) -Y ($bottomY + 92)
Draw-CenteredText -Graphics $graphics -Text "Scales Pods based`non CPU usage" -Font $labelFont -Brush $textBrush -X $hpaX -Y ($bottomY + 155) -Width $smallW -Height 62

Draw-PrometheusIcon -Graphics $graphics -CenterX ($promX + 130) -CenterY ($bottomY + 132)
Draw-CenteredText -Graphics $graphics -Text "Collects Metrics`n(CPU, Memory, etc.)" -Font $labelFont -Brush $textBrush -X $promX -Y ($bottomY + 156) -Width $smallW -Height 66

Draw-GrafanaIcon -Graphics $graphics -CenterX ($grafX + 130) -CenterY ($bottomY + 132)
Draw-CenteredText -Graphics $graphics -Text "Visualizes Metrics`n(Dashboards)" -Font $labelFont -Brush $textBrush -X $grafX -Y ($bottomY + 156) -Width $smallW -Height 66

# Connector lines from cluster to monitoring boxes
$clusterBottomX = $clusterX + ($clusterW / 2)
$clusterBottomY = $clusterY + $clusterH
$busY = 470
$graphics.DrawLine($linePen, $clusterBottomX, $clusterBottomY, $clusterBottomX, $busY)
$graphics.DrawLine($linePen, $hpaX + 130, $busY, $grafX + 130, $busY)
Draw-Arrow -Graphics $graphics -Pen $linePen -X1 ($hpaX + 130) -Y1 $busY -X2 ($hpaX + 130) -Y2 $bottomY
Draw-Arrow -Graphics $graphics -Pen $linePen -X1 ($promX + 130) -Y1 $busY -X2 ($promX + 130) -Y2 $bottomY
Draw-Arrow -Graphics $graphics -Pen $linePen -X1 ($grafX + 130) -Y1 $busY -X2 ($grafX + 130) -Y2 $bottomY
Draw-Arrow -Graphics $graphics -Pen $linePen -X1 ($promX + $smallW) -Y1 ($bottomY + 120) -X2 ($grafX - 10) -Y2 ($bottomY + 120)

$bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

$titleFont.Dispose()
$labelFont.Dispose()
$smallFont.Dispose()
$script:iconFont.Dispose()
$linePen.Dispose()
$boxFill.Dispose()
$appPen.Dispose()
$dockPen.Dispose()
$clusterPen.Dispose()
$path.Dispose()
$path2.Dispose()
$path3.Dispose()
$graphics.Dispose()
$bitmap.Dispose()

Write-Output "Generated: $outputPath"
