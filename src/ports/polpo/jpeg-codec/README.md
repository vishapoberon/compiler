# jpeg-codec

JPEG pictures for [polpo](https://github.com/polpo-system/polpo), in the console and in programs:
JPEG0 decodes and encodes them, and the commands of `jpeg` convert them. JPEG0 imports only Files, so
it runs on every port of polpo, without the desktop, and can be used in other Oberon systems.

```
portia.Install jpeg-codec
```

The repository has two more packages for the desktop:

- jpeg: JPEG. `jpg = JPEG.InitPicture` in the section PictureConverters of Oberon.Text makes
  Pictures.Open read .jpg files: the pictures of WebNav, Iris and every program on Pictures. They are
  drawn with the 256 colours of the palette of Display by RGBPictures of the package png. JPEG.Store
  writes a Picture as a JPEG file.
- images-jpeg: JPEGImages. `jpg = JPEGImages.Install` in ImageFormats makes Images.Load and
  Images.Store read and write .jpg files: pictures are loaded as BGR888, and transparent pixels are
  stored over white.

Both lines are in the Oberon.Text of polpo.

## Using

    jpeg.Info file ...                  size, components, baseline or progressive
    jpeg.ToPPM in.jpg out.ppm           the picture as PPM (P6)
    jpeg.FromPNM in out.jpg [quality]   a PPM, PGM or PAM picture as JPEG; quality 1 to 100 (75)
    jpeg.Copy in.jpg out.jpg [quality]  read and write again
    jpeg.Help

In a program:

    JPEG0.Decode(R, img, res)           img.width, img.height, img.pix: the rows from the top,
                                        4 bytes a pixel (red, green, blue, alpha always 255)
    JPEG0.Encode(W, img, quality, res)  a baseline JFIF picture
    JPEG0.ReadInfo(R, info, res)        the frame header only
    JPEG0.NewImage(w, h)                an image to fill and encode

Decode reads baseline and progressive JPEG pictures with Huffman coding and 8 bits a sample: grey,
YCbCr, RGB, CMYK and YCCK, with every sampling factor that divides the largest one, with or without
restart intervals. It refuses arithmetic coding, 12-bit samples, and lossless and hierarchical
pictures. A picture that is cut short is decoded as far as its data goes and grey after that, as
libjpeg does it.

The inverse DCT, the upsampling of the halved colours and the colour conversion compute as those of
libjpeg (its integer DCT "islow" and its "fancy upsampling"), so a picture decodes to the pixels djpeg
gives. There is one exception: in a progressive picture whose last scans are missing, libjpeg guesses
the missing coefficients of each block from the blocks around it (block smoothing), where JPEG0 leaves
them 0.

Encode writes YCbCr with the colours halved in both directions, or grey when every pixel is grey,
with the quantization tables of the JPEG specification scaled by the quality as libjpeg scales them,
and the Huffman tables of the specification. Decoded, its pictures have the same pixels as those cjpeg
writes with the same quality. Pictures may have up to 64 million pixels (MaxPixels); Encode writes
pictures of up to 65535 by 65535.

JPEG0 was written for polpo after the JPEG specification (ITU-T T.81) and the libjpeg of the
Independent JPEG Group, as libjpeg-turbo continues it: from libjpeg come the integer DCT, the
upsampling, the colour conversion, the refinement of progressive scans and the handling of data that
ends early. It replaces the decoder of ETH Oberon (JPEG of Oberon System 3, and JPEGImages of Linux
Oberon), which read only baseline pictures, wrote none, and drew into Pictures and Images itself.

## What is here

    src/JPEG0.Mod, src/jpeg.Mod                         package jpeg-codec
    desktop/JPEG.Mod                                    package jpeg
    desktop/JPEGImages.Mod                              package images-jpeg
    test/JPEGTest.Mod, jpegsuite.list, jpegsuite.tgz
    test/JPEGPicturesTest.Mod, test/JPEGImagesTest.Mod  (they need the desktop's display)

## Tests

    JPEGTest.Run jpegsuite.list   70 checks on the 38 pictures of jpegsuite.tgz: each of the 32 to
                                  decode decoded and its pixels compared by their CRC-32 with the
                                  list, then encoded with the quality 75, decoded again and compared;
                                  each of the 6 others refused with the expected result

    JPEGPicturesTest.Run          4 checks: Pictures.Open of a baseline, a progressive and a grey
                                  picture, their colours near those of JPEG0 (averaged over blocks
                                  of 4 by 4); a picture written by JPEG.Store read again
    JPEGImagesTest.Run            6 checks: Images.Load of the same three pictures (the pixels of
                                  JPEG0), Images.Store written and read again

cjpeg of libjpeg-turbo 3.1 made the pictures of jpegsuite.tgz out of small pictures of the plasma of
ImageMagick (97 by 61, 256 by 192, 61 by 47 grey, 15 by 17, 1 by 1):

    b444 b422 b420 b440 b411 b42x b31 bmix   baseline with the sampling 1x1, 2x1, 2x2, 1x2, 4x1,
                                             4x2, 3x1 and 1x1,2x2,1x1
    brgb bgrey bgrey2                        RGB; grey, of a grey and of a colour picture
    brst1 brst2                              restart intervals of a row and of 2 MCUs
    bopt bq100 bq3 bbig                      optimized Huffman tables; qualities 100, 3 and 85
    btiny bone bone444                       15 by 17, 1 by 1
    prog p444 p422 p440 pgrey                progressive: default, sampling 1x1, 2x1, 1x2; grey
    prst prst2 pq100 ptiny pone              progressive with restart intervals; quality 100;
                                             15 by 17, 1 by 1
    xtrunc xtruncp                           a baseline and a progressive picture cut short
    xarith x12bit xlossless                  refused: arithmetic coding, 12 bits, lossless
    xbaddqt xbadsof xnotjpeg                 refused: a DQT segment of length 1, a frame of 7
                                             components, a PPM file

The CRCs of jpegsuite.list were taken from JPEG0 after they had been compared with the pixels of
djpeg for every picture (all equal, but those of xtruncp.jpg, a progressive picture cut short), and
the CRCs after encoding with those of the pictures cjpeg -quality 75 (with -grayscale for grey
pictures) makes, decoded by djpeg (all equal). JPEG0 also decoded the 340 JPEG files of a Linux
system (photographs, pictures of manuals, backgrounds; 12 of them progressive) to the pixels of
djpeg. `portia.Install /t jpeg-codec` runs the test after unpacking `test/jpegsuite.tgz`.

## License

GPL-3 (`LICENSE`).
