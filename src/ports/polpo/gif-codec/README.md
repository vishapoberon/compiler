# gif-codec

GIF pictures for [polpo](https://github.com/polpo-system/polpo), in the console and in programs:
GIF0 decodes and encodes them, and the commands of `gif` convert them. GIF0 imports only Files, so it
runs on every port of polpo, without the desktop, and can be used in other Oberon systems.

```
portia.Install gif-codec
```

The repository has two more packages for the desktop:

- gif: GIF. `gif = GIF.InitPicture` in the section PictureConverters of Oberon.Text makes
  Pictures.Open read .gif files: the pictures of WebNav, Iris and every program on Pictures. They are
  drawn with the colours of the palette of Display by RGBPictures of the package png; Pictures have no
  transparency, so transparent pixels are white. GIF.Store writes a Picture as a GIF file.
- images-gif: GIFImages. `gif = GIFImages.Install` in ImageFormats makes Images.Load and
  Images.Store read and write .gif files: pictures with transparent pixels as BGRA8888, others as
  BGR888.

Both lines are in the Oberon.Text of polpo.

## Using

    gif.Info file ...           size, colours, images, interlace, transparency
    gif.ToPPM in.gif out.ppm    the picture as PPM (P6), transparent pixels black
    gif.ToPAM in.gif out.pam    the picture as PAM (P7, RGB_ALPHA), with its transparency
    gif.FromPNM in out.gif      a PPM (P6), PGM (P5) or PAM (P7) picture as GIF
    gif.Copy in.gif out.gif     read and write again
    gif.Help

In a program:

    GIF0.Decode(R, img, res)    img.width, img.height, img.alpha, img.pix: the rows from the top,
                                4 bytes a pixel (red, green, blue, alpha)
    GIF0.Encode(W, img, res)    a GIF89a file of one image
    GIF0.ReadInfo(R, info, res) the logical screen, the colour table, the number of images
    GIF0.NewImage(w, h)         an image to fill and encode

Decode reads GIF87a and GIF89a files and gives their first image (the first frame of an animation),
with its global or local colour table, interlaced or not, on a picture of the size of the logical
screen. Pixels outside the image and pixels of the transparent colour of its graphic control extension
have alpha 0 (and red, green and blue 0). Data that ends early, or a code that is not in the table,
ends the image where it is, as browsers show it; the pixels not decoded are transparent.

Encode writes one image with a global colour table. A picture of at most 256 colours keeps them
exactly; pixels with alpha below 128 become transparent, which leaves 255 colours for the others. A
picture with more colours gets 256 of them by median cut (the box of the most pixels is split at the
median of its longest side), and each pixel the nearest of them with Floyd-Steinberg dithering. The
LZW data is written as the encoder of Go's compress/lzw writes it, with a clear code when the table of
4096 codes is full. Pictures may have up to 64 million pixels (MaxPixels); Encode writes pictures of
up to 65535 by 65535.

GIF0 was written for polpo after the GIF89a specification. It replaces the readers of ETH Oberon (GIF
of Oberon System 3, GIFImages of Linux Oberon), which wrote no GIF files.

## What is here

    src/GIF0.Mod, src/gif.Mod                       package gif-codec
    desktop/GIF.Mod                                 package gif
    desktop/GIFImages.Mod                           package images-gif
    test/GIFTest.Mod, gifsuite.list, gifsuite.tgz
    test/GIFPicturesTest.Mod, test/GIFImagesTest.Mod  (they need the desktop's display)

## Tests

    GIFTest.Run gifsuite.list   39 checks: each of the 17 pictures of gifsuite.tgz to decode decoded,
                                its pixels compared by their CRC-32 with the list, encoded and decoded
                                again with the same pixels; each of the 3 others refused with the
                                expected result; a picture of 4096 colours made by the test, with and
                                without transparent pixels, encoded with at most 256 colours, its
                                transparency, and a mean difference of the components below 6
    GIFPicturesTest.Run         3 checks: Pictures.Open of a picture of 256 colours and one with
                                transparent pixels, their colours near those of GIF0; a picture written
                                by GIF.Store read again with the colours of every pixel
    GIFImagesTest.Run           6 checks: Images.Load of three pictures (the pixels of GIF0),
                                Images.Store written and read again with the same pixels

ImageMagick made the pictures of gifsuite.tgz out of pictures of its plasma and palette pictures of
PngSuite (Willem van Schaik): c2, small, c16, c256 (2, 7, 16 and 256 colours), inter (interlaced),
transp (a transparent colour), anim (an animation of two frames), one (1 by 1), basn3p01, basn3p02,
basn3p04, basn3p08, s01i3p01, s09n3p02, s35i3p04, tbbn3p08; xtrunc is c256 cut in the middle, and
xnotgif (a PPM file), xnoimage (no image) and xcodesize (a code size of 12) are refused. The CRCs of
gifsuite.list were taken from GIF0 after its pixels had been compared with those of ImageMagick
(-coalesce of the first frame) for every picture but xtrunc: all equal. GIF0 also decoded the 1535 GIF
files of a Linux system to the pixels of ImageMagick, and each of them encoded and decoded again
gave the same pixels; ImageMagick and giflib read the files GIF0 wrote with the same pixels as GIF0.
Two more files there were refused: a PNG file named .gif, and a damaged file that ImageMagick and
giflib refuse too. With 256 colours chosen for pictures of more, the pictures written are 0.2 to 1.4
dB further from the original than those of ImageMagick's -colors 256 (PSNR).

## License

GPL-3 (`LICENSE`). The pictures of PngSuite in gifsuite.tgz keep their own license
(`test/PngSuite.LICENSE`): they may be used, copied and distributed for any purpose.
