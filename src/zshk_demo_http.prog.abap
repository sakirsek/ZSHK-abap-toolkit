*&---------------------------------------------------------------------*
*& ZSHK_DEMO_HTTP — HTTP module demo
*&---------------------------------------------------------------------*
REPORT zshk_demo_http.

PARAMETERS p_url  TYPE text255 DEFAULT 'http://httpbin.org'.
PARAMETERS p_path TYPE text128 DEFAULT '/get'.
PARAMETERS p_meth TYPE char6 DEFAULT 'GET'.
PARAMETERS p_user TYPE text50.
PARAMETERS p_pwd  TYPE text50.
PARAMETERS p_body TYPE string.

START-OF-SELECTION.

  DATA(lo_http) = NEW zcl_shk_http( iv_url = p_url ).

  " set_timeout
  lo_http->zif_shk_http~set_timeout( 30 ).

  " set_header
  lo_http->zif_shk_http~set_header( iv_name = 'Accept' iv_value = 'application/json' ).
  lo_http->zif_shk_http~set_header( iv_name = 'X-Demo' iv_value = 'ZSHK-Toolkit' ).

  " set_basic_auth
  IF p_user IS NOT INITIAL.
    lo_http->zif_shk_http~set_basic_auth( iv_user = p_user iv_password = p_pwd ).
    WRITE: / |Auth: { p_user }|.
  ENDIF.

  WRITE: / |URL: { p_url }{ p_path }|.
  WRITE: / |Method: { p_meth }|.
  ULINE.

  TRY.
      DATA ls_resp TYPE zif_shk_http=>ty_s_response.

      CASE p_meth.
        WHEN 'GET'.
          " get
          ls_resp = lo_http->zif_shk_http~get( p_path ).
        WHEN 'POST'.
          " post
          ls_resp = lo_http->zif_shk_http~post( iv_path = p_path iv_body = p_body ).
        WHEN 'PUT'.
          " put
          ls_resp = lo_http->zif_shk_http~put( iv_path = p_path iv_body = p_body ).
        WHEN 'DELETE'.
          " delete
          ls_resp = lo_http->zif_shk_http~delete( p_path ).
        WHEN OTHERS.
          WRITE: / 'Invalid method. Use GET/POST/PUT/DELETE'.
          RETURN.
      ENDCASE.

      WRITE: / |Status: { ls_resp-status_code }|.
      ULINE.
      WRITE: / 'Response body:'.

      " truncate if too long
      IF strlen( ls_resp-body ) > 1000.
        WRITE: / ls_resp-body(1000).
        WRITE: / |... (truncated, total { strlen( ls_resp-body ) } chars)|.
      ELSE.
        WRITE: / ls_resp-body.
      ENDIF.

    CATCH zcx_shk_http INTO DATA(lo_err).
      WRITE: / 'HTTP error:', lo_err->get_text( ).
      IF lo_err->mv_status_code IS NOT INITIAL.
        WRITE: / |Status code: { lo_err->mv_status_code }|.
      ENDIF.
  ENDTRY.

  " close
  lo_http->zif_shk_http~close( ).
