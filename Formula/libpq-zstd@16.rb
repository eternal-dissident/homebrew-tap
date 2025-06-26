class LibpqZstdAT16 < Formula
  desc "Postgres C API library with zstd support"
  homepage "https://www.postgresql.org/docs/16/libpq.html"
  url "https://ftp.postgresql.org/pub/source/v16.9/postgresql-16.9.tar.bz2"
  sha256 "07c00fb824df0a0c295f249f44691b86e3266753b380c96f633c3311e10bd005"
  license "PostgreSQL"

  depends_on "pkgconf" => :build
  depends_on "icu4c@77"
  depends_on "krb5"
  depends_on "openssl@3"
  depends_on "zstd"

  uses_from_macos "zlib"

  def install
    system "./configure", "--disable-debug",
                          "--prefix=#{prefix}",
                          "--with-gssapi",
                          "--with-openssl",
                          "--with-zstd",
                          "--libdir=#{opt_lib}",
                          "--includedir=#{opt_include}"
    dirs = %W[
      libdir=#{lib}
      includedir=#{include}
      pkgincludedir=#{include}/postgresql
      includedir_server=#{include}/postgresql/server
      includedir_internal=#{include}/postgresql/internal
    ]
    system "make"
    system "make", "-C", "src/bin", "install", *dirs
    system "make", "-C", "src/include", "install", *dirs
    system "make", "-C", "src/interfaces", "install", *dirs
    system "make", "-C", "src/common", "install", *dirs
    system "make", "-C", "src/port", "install", *dirs
    system "make", "-C", "doc", "install", *dirs
  end

  test do
    (testpath/"libpq.c").write <<~EOS
      #include <stdlib.h>
      #include <stdio.h>
      #include <libpq-fe.h>
      int main() {
        const char *conninfo = "dbname = postgres";
        PGconn *conn = PQconnectdb(conninfo);
        if (PQstatus(conn) != CONNECTION_OK) {
          printf("Connection to database attempted and failed");
          PQfinish(conn);
          exit(0);
        }
        return 1;
      }
    EOS
    system ENV.cc, "libpq.c", "-L#{lib}", "-I#{include}", "-lpq", "-o", "libpqtest"
    assert_equal "Connection to database attempted and failed", shell_output("./libpqtest")
  end
end
