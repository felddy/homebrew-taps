class GnupgSharedSc < Formula
  desc "GNU Pretty Good Privacy (PGP) package with scdaemon shared access patch"
  homepage "https://gnupg.org/"
  url "https://gnupg.org/ftp/gcrypt/gnupg/gnupg-2.2.16.tar.bz2"
  sha256 "6cbe8d454bf5dc204621eed3016d721b66298fa95363395bb8eeceb1d2fd14cb"

  depends_on "pkg-config" => :build
  depends_on "sqlite" => :build if MacOS.version == :mavericks
  depends_on "adns"
  depends_on "gettext"
  depends_on "gnutls"
  depends_on "libassuan"
  depends_on "libgcrypt"
  depends_on "libgpg-error"
  depends_on "libksba"
  depends_on "libusb"
  depends_on "npth"
  depends_on "pinentry"
  depends_on "pinentry-mac"

  patch do
    url "https://raw.githubusercontent.com/GPGTools/MacGPG2/dev/patches/gnupg/scdaemon_shared-access.patch"
    sha256 "00ce4f14ee5690a9666a7b5dc2fd9e0ca1c02e02783b8a484c42b4704feac648"
  end

  def install
    system "./configure", "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}",
                          "--sbindir=#{bin}",
                          "--sysconfdir=#{etc}",
                          "--enable-all-tests",
                          "--enable-symcryptrun",
                          "--with-pinentry-pgm=#{Formula["pinentry"].opt_bin}/pinentry"
    system "make"
    system "make", "check"
    system "make", "install"
  end

  def post_install
    (var/"run").mkpath
    quiet_system "killall", "gpg-agent"
  end

  def caveats
    <<~EOS
      To activate smartcard shared access, add the following line
      to your .gnupg/scdaemon.conf:

        shared-access

    EOS
  end


  test do
    (testpath/"batch.gpg").write <<~EOS
      Key-Type: RSA
      Key-Length: 2048
      Subkey-Type: RSA
      Subkey-Length: 2048
      Name-Real: Testing
      Name-Email: testing@foo.bar
      Expire-Date: 1d
      %no-protection
      %commit
    EOS
    begin
      system bin/"gpg", "--batch", "--gen-key", "batch.gpg"
      (testpath/"test.txt").write "Hello World!"
      system bin/"gpg", "--detach-sign", "test.txt"
      system bin/"gpg", "--verify", "test.txt.sig"
    ensure
      system bin/"gpgconf", "--kill", "gpg-agent"
    end
  end
end
