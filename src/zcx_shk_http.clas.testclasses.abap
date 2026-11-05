CLASS ltc_text DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS long_text_stays_whole FOR TESTING.
    METHODS short_text_is_unchanged FOR TESTING.
    METHODS no_text_gives_no_text FOR TESTING.

ENDCLASS.


CLASS ltc_text IMPLEMENTATION.

  METHOD long_text_stays_whole.
    DATA(lv_text) = repeat( val = `x` occ = 120 ).
    DATA(lx_error) = NEW zcx_shk_http( iv_text = lv_text ).

    cl_abap_unit_assert=>assert_equals( act = lx_error->get_text( ) exp = lv_text ).
  ENDMETHOD.

  METHOD short_text_is_unchanged.
    DATA(lx_error) = NEW zcx_shk_http( iv_text = `Short reason` ).

    cl_abap_unit_assert=>assert_equals( act = lx_error->get_text( ) exp = `Short reason` ).
  ENDMETHOD.

  METHOD no_text_gives_no_text.
    DATA(lx_error) = NEW zcx_shk_http( ).

    cl_abap_unit_assert=>assert_initial( lx_error->get_text( ) ).
  ENDMETHOD.

ENDCLASS.
