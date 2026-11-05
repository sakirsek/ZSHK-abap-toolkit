CLASS ltc_mail DEFINITION DEFERRED.
CLASS zcl_shk_mail DEFINITION LOCAL FRIENDS ltc_mail.

CLASS ltc_mail DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_row,
        matnr TYPE c LENGTH 10,
        maktx TYPE c LENGTH 40,
      END OF ty_row,
      ty_rows TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

    DATA mo_cut TYPE REF TO zcl_shk_mail.

    METHODS setup.
    METHODS cells_are_escaped FOR TESTING.
    METHODS titles_are_escaped FOR TESTING.
    METHODS column_titles_used FOR TESTING.
    METHODS long_subject_kept FOR TESTING.
    METHODS html_body_is_not_inline FOR TESTING RAISING cx_static_check.
    METHODS html_mail_stays_single_part FOR TESTING RAISING cx_static_check.
    METHODS text_mail_uses_bcs_attachment FOR TESTING RAISING cx_static_check.

    METHODS assert_contains
      IMPORTING
        iv_html TYPE string
        iv_part TYPE string.

    METHODS assert_not_contains
      IMPORTING
        iv_html TYPE string
        iv_part TYPE string.

    METHODS add_attachment.

    METHODS mime_text
      RETURNING
        VALUE(rv_mime) TYPE string
      RAISING
        cx_static_check.

ENDCLASS.


CLASS ltc_mail IMPLEMENTATION.

  METHOD setup.
    mo_cut = NEW #( ).
    mo_cut->zif_shk_mail~set_subject( 'Test' ).
  ENDMETHOD.


  METHOD cells_are_escaped.
    DATA(lv_html) = mo_cut->render_table_html(
      VALUE ty_rows( ( matnr = 'MAT001' maktx = 'Kablo <2.5> & "A"' ) ) ).

    assert_contains( iv_html = lv_html iv_part = `<td>MAT001</td>` ).
    assert_contains( iv_html = lv_html iv_part = `<td>Kablo &lt;2.5&gt; &amp; "A"</td>` ).
  ENDMETHOD.


  METHOD titles_are_escaped.
    DATA(lv_html) = mo_cut->render_table_html(
      it_table   = VALUE ty_rows( ( matnr = 'MAT001' ) )
      it_columns = VALUE #( ( fieldname = 'MAKTX' title = 'Tanım <TR>' ) )
      iv_title   = 'Liste & özet' ).

    assert_contains( iv_html = lv_html iv_part = `<h3>Liste &amp; özet</h3>` ).
    assert_contains( iv_html = lv_html iv_part = `<td>Tanım &lt;TR&gt;</td>` ).
  ENDMETHOD.


  METHOD column_titles_used.
    DATA(lv_html) = mo_cut->render_table_html(
      it_table   = VALUE ty_rows( ( matnr = 'MAT001' maktx = 'Kablo' ) )
      it_columns = VALUE #( ( fieldname = 'MATNR' title = 'Malzeme' ) ) ).

    assert_contains( iv_html = lv_html iv_part = `<td>Malzeme</td><td>MAKTX</td>` ).
    assert_contains( iv_html = lv_html iv_part = `<tr><td>MAT001</td><td>Kablo</td></tr>` ).
  ENDMETHOD.


  METHOD long_subject_kept.
    DATA(lv_subject) = `ZSHK: a subject that is clearly longer than fifty characters in total`.

    mo_cut->zif_shk_mail~set_subject( lv_subject ).

    cl_abap_unit_assert=>assert_equals( act = mo_cut->mv_subject exp = lv_subject ).
    cl_abap_unit_assert=>assert_true( xsdbool( strlen( lv_subject ) > zcl_shk_mail=>c_short_subject_length ) ).
  ENDMETHOD.


  METHOD html_body_is_not_inline.
    mo_cut->zif_shk_mail~set_body_html( `<p>Deneme</p>` ).
    add_attachment( ).

    DATA(lv_mime) = mime_text( ).

    assert_contains( iv_html = lv_mime iv_part = `multipart/mixed` ).
    assert_contains( iv_html = lv_mime iv_part = `text/html` ).
    assert_contains( iv_html = lv_mime iv_part = `<p>Deneme</p>` ).
    assert_contains( iv_html = lv_mime iv_part = `Content-Disposition: attachment` ).
    assert_contains( iv_html = lv_mime iv_part = `filename="Dosya.xlsx"` ).
    assert_contains( iv_html = lv_mime iv_part = `QUJD` ).
    assert_not_contains( iv_html = lv_mime iv_part = `Content-Disposition: inline` ).
    assert_not_contains( iv_html = lv_mime iv_part = `text/plain` ).
  ENDMETHOD.


  METHOD html_mail_stays_single_part.
    mo_cut->zif_shk_mail~set_body_html( `<p>Deneme</p>` ).

    DATA(lv_mime) = mime_text( ).

    assert_contains( iv_html = lv_mime iv_part = `text/html` ).
    assert_not_contains( iv_html = lv_mime iv_part = `multipart/` ).
  ENDMETHOD.


  METHOD text_mail_uses_bcs_attachment.
    mo_cut->zif_shk_mail~set_body_text( `Deneme` ).
    add_attachment( ).

    DATA(lv_mime) = mime_text( ).

    assert_contains( iv_html = lv_mime iv_part = `multipart/mixed` ).
    assert_contains( iv_html = lv_mime iv_part = `Content-Disposition: inline` ).
    assert_contains( iv_html = lv_mime iv_part = `Dosya.xlsx` ).
  ENDMETHOD.


  METHOD assert_contains.
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( contains( val = iv_html sub = iv_part ) )
      msg = |"{ iv_part }" not found in { iv_html }| ).
  ENDMETHOD.


  METHOD assert_not_contains.
    cl_abap_unit_assert=>assert_false(
      act = xsdbool( contains( val = iv_html sub = iv_part ) )
      msg = |"{ iv_part }" unexpectedly found in { iv_html }| ).
  ENDMETHOD.


  METHOD add_attachment.
    DATA lv_file TYPE xstring.
    lv_file = '414243'.

    mo_cut->zif_shk_mail~add_attachment( iv_filename = 'Dosya.xlsx' iv_content = lv_file ).
  ENDMETHOD.


  METHOD mime_text.
    DATA(lv_mime) = CAST if_document_bcs( mo_cut->build_document( ) )->as_mime_document(
      NEW cl_sx_mime_singlepart( ) ).

    rv_mime = cl_abap_codepage=>convert_from( source = lv_mime codepage = `UTF-8` ).
  ENDMETHOD.

ENDCLASS.
