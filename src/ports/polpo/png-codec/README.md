# png-codec

PNG pictures for [polpo](https://github.com/polpo-system/polpo), in the console and in programs:
PNG0 decodes and encodes them, and the commands of `png` convert them. PNG0 imports only Files
and the zlib of ETH Oberon (Zlib, ZlibBuffers, ZlibInflate, ZlibDeflate), so it runs on every
port of polpo, without the desktop, and can be used in other Oberon systems that have these
modules.

```
portia.Install png-codec
```

The repository has two more packages for the desktop:

- png: PNG and RGBPictures. `png = PNG.InitPicture` in the section PictureConverters of
  Oberon.Text makes Pictures.Open read .png files: the pictures of WebNav and of every program on
  Pictures. Pictures are drawn with the 256 colours of the palette of Display (their own palette
  is not used, as with GIF and JPEG): RGBPictures gives each pixel the nearest of these colours,
  directly for a picture of at most 256 colours, with Floyd-Steinberg dithering for others;
  transparent pixels are blended over PNG.background (white).
  PNG.Store writes a Picture as a PNG file.
- images-png: PNGImages. `png = PNGImages.Install` in ImageFormats makes Images.Load and
  Images.Store read and write .png files: pictures with alpha as BGRA8888 (alpha premultiplied,
  as Images keeps it), others as BGR888.

Both lines are in the Oberon.Text of polpo after 1.4.0.

## Using

    png.Info file ...                size, bits per sample, colour type, interlace
    png.ToPPM in.png out.ppm         the picture as PPM (P6), without its alpha
    png.ToPAM in.png out.pam         the picture as PAM (P7, RGB_ALPHA), with its alpha
    png.FromPNM in out.png [level]   a PPM or PAM picture as PNG; level 0 to 9 (zlib)
    png.Copy in.png out.png [level]  read and write again
    png.Help

In a program:

    PNG0.Decode(R, img, res)         img.width, img.height, img.alpha, img.pix: the rows from
                                     the top, 4 bytes a pixel (red, green, blue, alpha)
    PNG0.Encode(W, img, level, res)  8-bit RGB, or RGBA if img.alpha
    PNG0.ReadInfo(R, info, res)      the header only
    PNG0.NewImage(w, h)              an image to fill and encode

Decode reads every kind of PNG picture: grey, grey with alpha, RGB, RGB with alpha and palette
pictures, with 1, 2, 4, 8 or 16 bits per sample (16 are reduced to 8), interlaced or not, with
the transparency of a tRNS chunk. It checks the CRC of every chunk and refuses unknown critical
chunks; ancillary chunks (gamma, text, time and so on) are skipped. Encode chooses for each row
the filter that gives the smallest sum of its bytes taken as signed numbers. Pictures may have up
to 64 million pixels (MaxPixels).

PNG0 was written for polpo after the PNG 1.2 specification and the decoders of TF
(AosPNGImages of Bluebottle, back-ported to Oberon System 3 as PNG.Mod). It inflates the picture
data with ZlibInflate called in a loop on pieces of 4096 bytes, as ZlibReaders does; in polpo 1.4.0
and before, ZlibInflate.Uncompress, which calls Inflate once with Finish, stopped after 32 KB of
output.

## What is here

    src/PNG0.Mod, src/png.Mod                         package png-codec
    desktop/PNG.Mod, desktop/RGBPictures.Mod          package png
    desktop/PNGImages.Mod                             package images-png
    test/PNGTest.Mod, pngsuite.list, PngSuite-2017jul19.tgz
    test/PNGPicturesTest.Mod, test/PNGImagesTest.Mod  (they need the desktop's display)

## Tests

    PNGTest.Run pngsuite.list    338 checks on the 176 pictures of PngSuite (Willem van Schaik):
                                 each of the 162 valid pictures decoded, its pixels compared by
                                 their CRC-32 with the list, then encoded and decoded again; each
                                 of the 14 damaged ones refused with the expected result

    PNGPicturesTest.Run          2 checks: Pictures.Open of an RGB and a palette picture, their
                                 colours near those of PNG0 (averaged over blocks of 4 by 4)
    PNGImagesTest.Run            4 checks: Images.Load of an RGB and an RGBA picture (the pixels
                                 of PNG0), Images.Store written and read again

The CRCs of `test/pngsuite.list` were taken from PNG0 after its pixels had been compared with
those of libpng (ImageMagick) for every picture: they are equal, except that libpng rounds 16-bit
samples to 8 bits where PNG0 keeps the more significant byte (a difference of at most 1). The
pictures PNG0 encodes were read again by libpng with the same pixels. `portia.Install /t
png-codec` runs the test after unpacking `test/PngSuite-2017jul19.tgz`.

The tests found a bug in the zlib of polpo: Zlib.Adler32 summed up to 5552 bytes before reducing
its sums, the bound zlib has for unsigned 32-bit numbers; Oberon's LONGINT is signed, and on long
runs of high bytes the sum wrapped, so valid streams were refused and streams written had a
wrong checksum. polpo after 1.4.0 has the fix (3854 bytes), and also a ZlibInflate.Uncompress and a
ZlibDeflate.Compress at level 0 that work on large data.

## License

GPL-3 (`LICENSE`). PngSuite keeps its own license (`test/PngSuite.LICENSE`): it may be used,
copied and distributed for any purpose.
