*&---------------------------------------------------------------------*
*& ZSHK_DEMO_PROGRESS — Progress module demo
*&---------------------------------------------------------------------*
REPORT zshk_demo_progress.

PARAMETERS p_total TYPE i DEFAULT 50.

START-OF-SELECTION.

  " constructor
  DATA(lo_prog) = NEW zcl_shk_progress(
    iv_total = p_total
    iv_text  = 'Processing records' ).

  DATA lv_dummy TYPE i.

  DO p_total TIMES.
    " increment
    lo_prog->increment( ).

    " simulate work with a small computation loop
    DO 500000 TIMES.
      lv_dummy = sy-index * 2.
    ENDDO.
  ENDDO.

  " get_percentage
  DATA(lv_pct) = lo_prog->get_percentage( ).
  WRITE: / |Final percentage: { lv_pct }%|.

  " get_elapsed
  DATA(lv_elapsed) = lo_prog->get_elapsed( ).
  WRITE: / |Elapsed: { lv_elapsed } seconds|.

  ULINE.

  " update with custom text
  DATA(lo_prog2) = NEW zcl_shk_progress( iv_total = 3 iv_text = 'Steps' ).

  lo_prog2->update( iv_current = 1 iv_text = 'Step 1: Reading data' ).
  DO 1000000 TIMES.
    lv_dummy = sy-index * 2.
  ENDDO.

  lo_prog2->update( iv_current = 2 iv_text = 'Step 2: Processing' ).
  DO 1000000 TIMES.
    lv_dummy = sy-index * 2.
  ENDDO.

  " get_eta
  DATA(lv_eta) = lo_prog2->get_eta( ).
  WRITE: / |ETA before last step: { lv_eta } seconds|.

  lo_prog2->update( iv_current = 3 iv_text = 'Step 3: Complete' ).

  WRITE: / |Total elapsed: { lo_prog2->get_elapsed( ) } seconds|.
  WRITE: / 'Done.'.
