CLASS ltc_parse_listing DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS unix_long_listing FOR TESTING.
    METHODS unix_without_group FOR TESTING.
    METHODS unix_name_with_blanks FOR TESTING.
    METHODS windows_iis_listing FOR TESTING.
    METHODS plain_names_and_paths FOR TESTING.
    METHODS reply_lines_skipped FOR TESTING.
    METHODS sapftp_echo_and_notes_skipped FOR TESTING.
    METHODS mask_is_case_insensitive FOR TESTING.

ENDCLASS.


CLASS ltc_parse_listing IMPLEMENTATION.

  METHOD unix_long_listing.
    DATA(lt_files) = zcl_shk_ftp=>parse_listing( VALUE #(
      ( `drwxr-xr-x    2 ftp      ftp          4096 Apr 28 11:38 Archive` )
      ( `-rw-r--r--    1 ftp      ftp          1234 Sep 29 10:15 DESADV_001.edi` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_files ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lt_files[ 1 ]-name exp = `DESADV_001.edi` ).
    cl_abap_unit_assert=>assert_equals( act = lt_files[ 1 ]-size exp = 1234 ).
    cl_abap_unit_assert=>assert_equals( act = lt_files[ 1 ]-date exp = `Sep 29 10:15` ).
  ENDMETHOD.

  METHOD unix_without_group.
    DATA(lt_files) = zcl_shk_ftp=>parse_listing( VALUE #(
      ( `-rw-r--r-- 1 ftp 77 Jan  5  2025 a.txt` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = lt_files[ 1 ]-name exp = `a.txt` ).
    cl_abap_unit_assert=>assert_equals( act = lt_files[ 1 ]-size exp = 77 ).
  ENDMETHOD.

  METHOD unix_name_with_blanks.
    DATA(lt_files) = zcl_shk_ftp=>parse_listing( VALUE #(
      ( `-rw-r--r-- 1 ftp ftp 10 Sep 29 10:15 MD ELEK  asn.txt` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = lt_files[ 1 ]-name exp = `MD ELEK  asn.txt` ).
  ENDMETHOD.

  METHOD windows_iis_listing.
    DATA(lt_files) = zcl_shk_ftp=>parse_listing( VALUE #(
      ( `04-28-26  11:38AM       <DIR>          Archive` )
      ( |09-29-26  10:15AM                 5678 ASN_1.txt{ cl_abap_char_utilities=>cr_lf(1) }| ) ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_files ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lt_files[ 1 ]-name exp = `ASN_1.txt` ).
    cl_abap_unit_assert=>assert_equals( act = lt_files[ 1 ]-size exp = 5678 ).
  ENDMETHOD.

  METHOD plain_names_and_paths.
    DATA(lt_files) = zcl_shk_ftp=>parse_listing( VALUE #(
      ( `a.edi` )
      ( `/ACOME/OUT/b.edi` )
      ( `.` )
      ( `..` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_files ) exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = lt_files[ 2 ]-name exp = `b.edi` ).
    cl_abap_unit_assert=>assert_equals( act = lt_files[ 2 ]-size exp = 0 ).
  ENDMETHOD.

  METHOD reply_lines_skipped.
    DATA(lt_files) = zcl_shk_ftp=>parse_listing( VALUE #(
      ( `ftp> dir .` )
      ( `227 Entering Passive Mode (10,249,33,61,195,80).` )
      ( `150 Opening ASCII mode data connection.` )
      ( `total 8` )
      ( `` )
      ( `-rw-r--r-- 1 ftp ftp 1 Sep 29 10:15 x.edi` )
      ( `226 Transfer complete.` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_files ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lt_files[ 1 ]-name exp = `x.edi` ).
  ENDMETHOD.

  METHOD sapftp_echo_and_notes_skipped.
    DATA(lt_files) = zcl_shk_ftp=>parse_listing( VALUE #(
      ( `dir .` )
      ( `227 Entering Passive Mode (10,249,33,61,232,205)` )
      ( `Passive mode: Connected to Port -5939.` )
      ( `150 Starting data transfer.` )
      ( `drwxrwxrwx 1 ftp ftp 0 Oct 01 14:20 Archive` )
      ( `226 Operation successful` ) ) ).
    cl_abap_unit_assert=>assert_initial( lt_files ).
  ENDMETHOD.

  METHOD mask_is_case_insensitive.
    DATA(lt_files) = zcl_shk_ftp=>parse_listing(
      it_lines = VALUE #( ( `x.edi` ) ( `Y.EDI` ) ( `z.txt` ) )
      iv_mask  = '*.Edi' ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_files ) exp = 2 ).
  ENDMETHOD.

ENDCLASS.
