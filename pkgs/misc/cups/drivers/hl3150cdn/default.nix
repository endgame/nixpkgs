{stdenv, fetchurl, cups, dpkg, gnused, makeWrapper, ghostscript, file, a2ps, coreutils, gawk}:

let
  version = "1.1.4-0";
  cupsdeb = fetchurl {
    url = "https://download.brother.com/welcome/dlf100434/hl3150cdncupswrapper-${version}.i386.deb";
    sha256 = "17vsawbf70cjsdxzhd7dd8sk2dx1z0hjw322s23qvm44m04dz3z3";
  };
  srcdir = "hl3150cdn_cupswrapper_GPL_source_${version}";
  cupssrc = fetchurl {
    url = "https://download.brother.com/welcome/dlf006741/hl3150cdn_cupswrapper_GPL_source_${version}.tar.gz";
    sha256 = "1rca7pp9naynz8j5yhxwxjvwm1pxxbqplwmc4sc5m9zvyb3id3pw";
  };
  lprdeb = fetchurl {
    url = "https://download.brother.com/welcome/dlf100432/hl3150cdnlpr-1.1.2-1.i386.deb";
    sha256 = "03dvz2zxv9zpkxfhi2ynranbqbi4zf6488nzmi6f78h3wp9rd4ja";
  };
in
stdenv.mkDerivation {
  name = "cups-brother-hl3150cdn";
  nativeBuildInputs = [ makeWrapper dpkg ];
  buildInputs = [ cups ghostscript a2ps ];

  unpackPhase = ''
    tar -xvf ${cupssrc}
  '';

  buildPhase = ''
    gcc -Wall ${srcdir}/brcupsconfig/brcupsconfig.c -o brcupsconfpt1
  '';

  installPhase = ''
    # install lpr
    dpkg-deb -x ${lprdeb} $out

    substituteInPlace $out/opt/brother/Printers/hl3150cdn/lpd/filterhl3150cdn \
      --replace /opt "$out/opt"
    substituteInPlace $out/opt/brother/Printers/hl3150cdn/inf/setupPrintcapij \
      --replace /opt "$out/opt"

    sed -i '/GHOST_SCRIPT=/c\GHOST_SCRIPT=gs' $out/opt/brother/Printers/hl3150cdn/lpd/psconvertij2

    patchelf --set-interpreter ${stdenv.glibc.out}/lib/ld-linux.so.2 $out/opt/brother/Printers/hl3150cdn/lpd/brhl3150cdnfilter
    patchelf --set-interpreter ${stdenv.glibc.out}/lib/ld-linux.so.2 $out/usr/bin/brprintconf_hl3150cdn

    wrapProgram $out/opt/brother/Printers/hl3150cdn/lpd/psconvertij2 \
      --prefix PATH ":" ${ stdenv.lib.makeBinPath [ gnused coreutils gawk ] }

    wrapProgram $out/opt/brother/Printers/hl3150cdn/lpd/filterhl3150cdn \
      --prefix PATH ":" ${ stdenv.lib.makeBinPath [ ghostscript a2ps file gnused coreutils ] }


    dpkg-deb -x ${cupsdeb} $out

    substituteInPlace $out/opt/brother/Printers/hl3150cdn/cupswrapper/cupswrapperhl3150cdn \
      --replace /opt "$out/opt"

    mkdir -p $out/lib/cups/filter
    ln -s $out/opt/brother/Printers/hl3150cdn/cupswrapper/cupswrapperhl3150cdn $out/lib/cups/filter/cupswrapperhl3150cdn

    ln -s $out/opt/brother/Printers/hl3150cdn/cupswrapper/brother_hl3150cdn_printer_en.ppd $out/lib/cups/filter/brother_hl3150cdn_printer_en.ppd

    cp brcupsconfpt1 $out/opt/brother/Printers/hl3150cdn/cupswrapper/
    ln -s $out/opt/brother/Printers/hl3150cdn/cupswrapper/brcupsconfpt1 $out/lib/cups/filter/brcupsconfpt1
    ln -s $out/opt/brother/Printers/hl3150cdn/lpd/filterhl3150cdn $out/lib/cups/filter/brother_lpdwrapper_hl3150cdn

    wrapProgram $out/opt/brother/Printers/hl3150cdn/cupswrapper/cupswrapperhl3150cdn \
      --prefix PATH ":" ${ stdenv.lib.makeBinPath [ gnused coreutils gawk ] }
  '';

  meta = {
    homepage = http://www.brother.com/;
    description = "Brother hl3150cdn printer driver";
    license = stdenv.lib.licenses.unfree;
    platforms = stdenv.lib.platforms.linux;
    downloadPage = "https://support.brother.com/g/b/downloadlist.aspx?c=au&lang=en&prod=hl3150cdn_us_as_cn&os=128";
  };
}
