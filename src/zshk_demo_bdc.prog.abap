*&---------------------------------------------------------------------*
*& ZSHK_DEMO_BDC — BDC module demo
*&---------------------------------------------------------------------*
REPORT zshk_demo_bdc.

PARAMETERS:
  p_tcode TYPE sytcode DEFAULT 'SE16',
  p_table TYPE tabname DEFAULT 'T001',
  p_run   TYPE abap_bool AS CHECKBOX DEFAULT ' '.

START-OF-SELECTION.

  DATA(lo_bdc) = NEW zcl_shk_bdc( ).

  " add_screen — SE16 initial screen
  lo_bdc->zif_shk_bdc~add_screen( iv_program = 'SAPLSE16' iv_dynpro = '0100' ).

  " add_field
  lo_bdc->zif_shk_bdc~add_field( iv_name = 'SE16-DTAB' iv_value = CONV #( p_table ) ).

  " add_okcode
  lo_bdc->zif_shk_bdc~add_okcode( '=ONLI' ).

  " get_bdcdata — inspect before execution
  DATA(lt_bdcdata) = lo_bdc->zif_shk_bdc~get_bdcdata( ).
  WRITE: / |BDC data prepared: { lines( lt_bdcdata ) } entries|.
  ULINE.
  WRITE: / 'PROGRAM', 30 'DYNPRO', 40 'FNAM', 75 'FVAL'.
  ULINE.
  LOOP AT lt_bdcdata INTO DATA(ls_bdc).
    WRITE: / ls_bdc-program, 30 ls_bdc-dynpro, 40 ls_bdc-fnam, 75 ls_bdc-fval.
  ENDLOOP.
  ULINE.

  IF p_run = abap_true.
    " execute — run the transaction
    TRY.
        DATA(lt_msg) = lo_bdc->zif_shk_bdc~execute(
          iv_tcode   = p_tcode
          iv_dismode = 'A'
          iv_updmode = 'S' ).

        WRITE: / |Execution returned { lines( lt_msg ) } messages:|.
        LOOP AT lt_msg INTO DATA(ls_msg).
          WRITE: / |  { ls_msg-type }: { ls_msg-message }|.
        ENDLOOP.

      CATCH zcx_shk_bdc INTO DATA(lo_err).
        WRITE: / |BDC error: { lo_err->get_text( ) }|.
    ENDTRY.
  ELSE.
    WRITE: / 'Check "Execute" to run the transaction'.

    " clear
    lo_bdc->zif_shk_bdc~clear( ).
    WRITE: / |After clear: { lines( lo_bdc->zif_shk_bdc~get_bdcdata( ) ) } entries|.
  ENDIF.
