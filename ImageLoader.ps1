[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 

# Read the entire file to an array of bytes.
$bytes = [System.IO.File]::ReadAllBytes((((Get-Location).Path) + "\map_pic.pcx"))
# Decode first 12 bytes to a text assuming ASCII encoding.
#$text = [System.Text.Encoding]::ASCII.GetString($bytes, 0, 12)

$offsetPalette = $bytes.Count - 768
Write-Host "OffsetPalette: $offsetPalette"

$palette = @{}
#$imgPalette = New-Object System.Drawing.Bitmap(256, 1);

for($i = 0; $i -lt 256; $i++)
{
    $palette[$i] = [System.Drawing.Color]::FromArgb(255, ($bytes[($i * 3 + $offsetPalette)]), ($bytes[($i * 3 + $offsetPalette + 1)]), ($bytes[($i * 3 + $offsetPalette + 2)])); 
    #$imgPalette.SetPixel($i, 0, ($palette[$i]));
}

#$imgPalette.Save(($PSScriptRoot + "\" + "Palette" + ".png"))

$ImageSizeX = $bytes[8] + $bytes[9] * 256 + 1
$ImageSizeY = $bytes[10] + $bytes[11] * 256 + 1

Write-Host "Creating Image of Size: $ImageSizeX by $ImageSizeY"

$imgImage = New-Object System.Drawing.Bitmap($ImageSizeX, $ImageSizeY);

$pixelOffset = 0

for($i = 128; $i -lt ($offsetPalette - 1); $i++)
{

    # if the first 2 Bits are set, this is a length
    if([int]$bytes[$i] -gt 192)
    {
        for($j = 0; $j -lt ([int]$bytes[$i] - 192); $j++)
        {
            $y = [math]::floor($pixelOffset / $ImageSizeX)
            $x = [math]::floor($pixelOffset - ($y * $ImageSizeX))

            $imgImage.SetPixel($x, $y, ($palette[[int]($bytes[($i + 1)])]));

            $pixelOffset++;
        }

        # increase i by 1 as we have to read the next byte
        $i++
    }
    # just a color index
    else
    {
        $y = [math]::floor($pixelOffset / $ImageSizeX)
        $x = [math]::floor($pixelOffset - ($y * $ImageSizeX))

        $imgImage.SetPixel($x, $y, ($palette[[int]($bytes[$i])]));

        if([int]($bytes[($i + 1)]) -eq 154) {$clrCounter++}

        $pixelOffset++;
    }
}

$imgImage.Save((((Get-Location).Path) + "\" + "Image" + ".png"))