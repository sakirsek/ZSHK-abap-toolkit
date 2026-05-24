*&---------------------------------------------------------------------*
*& ZSHK_DEMO_CSV — CSV module demo
*&---------------------------------------------------------------------*
REPORT zshk_demo_csv.

PARAMETERS p_sep TYPE c DEFAULT ';'.

TYPES:
  BEGIN OF ty_material,
    matnr TYPE matnr,
    maktx TYPE maktx,
    meins TYPE meins,
    ntgew TYPE ntgew,
  END OF ty_material.

START-OF-SELECTION.

  DATA lt_data TYPE STANDARD TABLE OF ty_material.
  lt_data = VALUE #(
    ( matnr = 'MAT001' maktx = 'Kablo 2.5mm' meins = 'MT' ntgew = '125.50' )
    ( matnr = 'MAT002' maktx = 'Terminal Tip A' meins = 'AD' ntgew = '0.35' )
    ( matnr = 'MAT003' maktx = 'Conta 10x15' meins = 'AD' ntgew = '1.20' ) ).

  DATA lv_lines TYPE i.
  lv_lines = lines( lt_data ).
  WRITE: / 'Source table:', lv_lines, 'rows'.
  ULINE.

  " table_to_csv (with header)
  DATA(lv_csv) = zcl_shk_csv=>table_to_csv(
    it_table       = lt_data
    iv_separator   = p_sep
    iv_with_header = abap_true ).
  WRITE: / 'table_to_csv (with header):'.
  WRITE: / lv_csv.
  ULINE.

  " table_to_csv (without header)
  DATA(lv_csv_nh) = zcl_shk_csv=>table_to_csv(
    it_table       = lt_data
    iv_separator   = p_sep
    iv_with_header = abap_false ).
  WRITE: / 'table_to_csv (no header):'.
  WRITE: / lv_csv_nh.
  ULINE.

  " csv_to_table (parse back)
  DATA lt_parsed TYPE STANDARD TABLE OF ty_material.
  zcl_shk_csv=>csv_to_table(
    EXPORTING
      iv_csv         = lv_csv
      iv_separator   = p_sep
      iv_skip_header = abap_true
    CHANGING
      ct_table       = lt_parsed ).

  DATA lv_parsed_cnt TYPE i.
  lv_parsed_cnt = lines( lt_parsed ).
  WRITE: / 'csv_to_table:', lv_parsed_cnt, 'rows parsed back'.
  LOOP AT lt_parsed INTO DATA(ls_row).
    WRITE: / '  ', ls_row-matnr, ls_row-maktx, ls_row-meins, ls_row-ntgew.
  ENDLOOP.
  ULINE.

  " to_xstring (UTF-8)
  DATA(lv_xstr) = zcl_shk_csv=>to_xstring( iv_csv = lv_csv iv_encoding = '4110' ).
  DATA lv_len TYPE i.
  lv_len = xstrlen( lv_xstr ).
  WRITE: / 'to_xstring (UTF-8):', lv_len, 'bytes'.

  " to_xstring (Windows-1254 Turkish)
  DATA(lv_xstr_tr) = zcl_shk_csv=>to_xstring( iv_csv = lv_csv iv_encoding = '1610' ).
  lv_len = xstrlen( lv_xstr_tr ).
  WRITE: / 'to_xstring (Win-1254):', lv_len, 'bytes'.
