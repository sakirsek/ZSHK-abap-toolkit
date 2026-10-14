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

    METHODS assert_contains
      IMPORTING
        iv_html TYPE string
        iv_part TYPE string.

ENDCLASS.


CLASS ltc_mail IMPLEMENTATION.

  METHOD setup.
    mo_cut = NEW #( ).
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


  METHOD assert_contains.
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( contains( val = iv_html sub = iv_part ) )
      msg = |"{ iv_part }" not found in { iv_html }| ).
  ENDMETHOD.

ENDCLASS.
