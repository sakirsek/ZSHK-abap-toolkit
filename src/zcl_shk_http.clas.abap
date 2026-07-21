CLASS zcl_shk_http DEFINITION
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_shk_http.

    METHODS constructor
      IMPORTING
        iv_url         TYPE clike
        iv_ssl_id      TYPE ssfapplssl DEFAULT 'ANONYM'
        iv_proxy_host  TYPE clike OPTIONAL
        iv_proxy_port  TYPE clike OPTIONAL.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mv_url        TYPE string.
    DATA mv_ssl_id     TYPE ssfapplssl.
    DATA mv_proxy_host TYPE string.
    DATA mv_proxy_port TYPE string.
    DATA mv_timeout    TYPE i VALUE 30.
    DATA mt_headers    TYPE zif_shk_http=>ty_t_name_value.
    DATA mv_user       TYPE string.
    DATA mv_password   TYPE string.

    METHODS execute
      IMPORTING
        iv_method        TYPE string
        iv_path          TYPE clike DEFAULT ''
        iv_body          TYPE clike DEFAULT ''
      RETURNING
        VALUE(rs_response) TYPE zif_shk_http=>ty_s_response
      RAISING
        zcx_shk_http.
ENDCLASS.

CLASS zcl_shk_http IMPLEMENTATION.
  METHOD constructor.
    mv_url        = iv_url.
    mv_ssl_id     = iv_ssl_id.
    mv_proxy_host = iv_proxy_host.
    mv_proxy_port = iv_proxy_port.
  ENDMETHOD.

  METHOD zif_shk_http~set_header.
    APPEND VALUE zif_shk_http=>ty_s_name_value( name = iv_name value = iv_value ) TO mt_headers.
    ro_self = me.
  ENDMETHOD.

  METHOD zif_shk_http~set_timeout.
    mv_timeout = iv_timeout.
    ro_self = me.
  ENDMETHOD.

  METHOD zif_shk_http~set_basic_auth.
    mv_user     = iv_user.
    mv_password = iv_password.
    ro_self = me.
  ENDMETHOD.

  METHOD zif_shk_http~get.
    rs_response = execute( iv_method = 'GET' iv_path = iv_path ).
  ENDMETHOD.

  METHOD zif_shk_http~post.
    rs_response = execute( iv_method = 'POST' iv_path = iv_path iv_body = iv_body ).
  ENDMETHOD.

  METHOD zif_shk_http~put.
    rs_response = execute( iv_method = 'PUT' iv_path = iv_path iv_body = iv_body ).
  ENDMETHOD.

  METHOD zif_shk_http~patch.
    rs_response = execute( iv_method = 'PATCH' iv_path = iv_path iv_body = iv_body ).
  ENDMETHOD.

  METHOD zif_shk_http~delete.
    rs_response = execute( iv_method = 'DELETE' iv_path = iv_path ).
  ENDMETHOD.

  METHOD zif_shk_http~close.
    CLEAR: mt_headers, mv_user, mv_password.
  ENDMETHOD.

  METHOD execute.
    DATA lv_full_url TYPE string.
    IF iv_path IS NOT INITIAL.
      lv_full_url = mv_url && iv_path.
    ELSE.
      lv_full_url = mv_url.
    ENDIF.

    DATA lo_client TYPE REF TO if_http_client.

    cl_http_client=>create_by_url(
      EXPORTING
        url                = lv_full_url
        ssl_id             = mv_ssl_id
        proxy_host         = CONV #( mv_proxy_host )
        proxy_service      = CONV #( mv_proxy_port )
      IMPORTING
        client             = lo_client
      EXCEPTIONS
        argument_not_found = 1
        plugin_not_active  = 2
        internal_error     = 3
        OTHERS             = 4 ).

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_shk_http
        EXPORTING iv_text = |HTTP client creation failed for { lv_full_url }: { sy-msgv1 }|.
    ENDIF.

    lo_client->request->set_method( iv_method ).
    lo_client->propertytype_logon_popup = lo_client->co_disabled.

    lo_client->request->set_header_field(
      name  = '~request_method'
      value = iv_method ).

    IF mv_user IS NOT INITIAL.
      lo_client->authenticate(
        username = mv_user
        password = mv_password ).
    ENDIF.

    lo_client->request->set_header_field(
      name  = 'Content-Type'
      value = 'application/json; charset=utf-8' ).

    LOOP AT mt_headers INTO DATA(ls_header).
      lo_client->request->set_header_field(
        name  = CONV #( ls_header-name )
        value = CONV #( ls_header-value ) ).
    ENDLOOP.

    IF iv_body IS NOT INITIAL.
      lo_client->request->set_cdata( CONV #( iv_body ) ).
    ENDIF.

    lo_client->send(
      EXPORTING timeout = mv_timeout
      EXCEPTIONS
        http_communication_failure = 1
        http_invalid_state         = 2
        http_processing_failed     = 3
        OTHERS                     = 4 ).

    IF sy-subrc <> 0.
      DATA lv_msg TYPE string.
      lo_client->get_last_error( IMPORTING message = lv_msg ).
      lo_client->close( ).
      RAISE EXCEPTION TYPE zcx_shk_http
        EXPORTING iv_text = |HTTP send failed: { lv_msg }|.
    ENDIF.

    lo_client->receive(
      EXCEPTIONS
        http_communication_failure = 1
        http_invalid_state         = 2
        http_processing_failed     = 3
        OTHERS                     = 4 ).

    IF sy-subrc <> 0.
      lo_client->get_last_error( IMPORTING message = lv_msg ).
      lo_client->close( ).
      RAISE EXCEPTION TYPE zcx_shk_http
        EXPORTING iv_text = |HTTP receive failed: { lv_msg }|.
    ENDIF.

    lo_client->response->get_status(
      IMPORTING code = rs_response-status_code ).

    rs_response-body = lo_client->response->get_cdata( ).

    lo_client->close( ).
  ENDMETHOD.
ENDCLASS.
