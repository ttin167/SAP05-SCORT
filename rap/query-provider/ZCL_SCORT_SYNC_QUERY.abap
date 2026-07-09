

CLASS zcl_scort_sync_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider .

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_query_params,
        devclass     TYPE devclass,
        object_type  TYPE trobjtype,
        author       TYPE uname,
        name_pattern TYPE string,
      END OF ty_query_params .

    TYPES tt_sync_result TYPE STANDARD TABLE OF zi_scort_repository_sync WITH DEFAULT KEY .

    METHODS parse_filter
      IMPORTING
        io_request TYPE REF TO if_rap_query_request
      RETURNING
        VALUE(rs_params) TYPE ty_query_params .

    METHODS call_target_objects
      IMPORTING
        is_params TYPE ty_query_params
      EXPORTING
        et_target    TYPE zscort_t_rfc_object
        ev_reachable TYPE abap_bool .

    METHODS build_matrix
      IMPORTING
        io_repo   TYPE REF TO zcl_scort_repository
        is_params TYPE ty_query_params
      RETURNING
        VALUE(rt_result) TYPE tt_sync_result .

ENDCLASS.


CLASS zcl_scort_sync_query IMPLEMENTATION.


  METHOD parse_filter.

    DATA lv_fname TYPE string.
    DATA lo_filter TYPE REF TO if_rap_query_filter.

    lo_filter = io_request->get_filter( ).
    CHECK lo_filter IS BOUND.

    TRY.
        DATA(lt_ranges) = lo_filter->get_as_ranges( ).
      CATCH cx_root.
        RETURN.
    ENDTRY.

    LOOP AT lt_ranges INTO DATA(ls_pair).
      lv_fname = ls_pair-name.
      TRANSLATE lv_fname TO UPPER CASE.

      LOOP AT ls_pair-range INTO DATA(ls_r).
        CHECK ls_r-sign <> 'E' AND ls_r-low IS NOT INITIAL.

        CASE lv_fname.
          WHEN 'DEVCLASS' OR 'DEV_CLASS'.
            rs_params-devclass = ls_r-low.

          WHEN 'OBJECTTYPE' OR 'OBJECT_TYPE'.
            rs_params-object_type = ls_r-low.

          WHEN 'AUTHOR'.
            rs_params-author = ls_r-low.

          WHEN 'OBJECTNAME' OR 'OBJECT_NAME'.
            rs_params-name_pattern = ls_r-low.
            IF ls_r-option = 'CP' AND find( val = rs_params-name_pattern sub = '*' ) < 0.
              rs_params-name_pattern = |*{ rs_params-name_pattern }*|.
            ENDIF.
        ENDCASE.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.


  METHOD call_target_objects.


    DATA lo_rfc   TYPE REF TO zcl_scort_rfc_service.
    DATA lv_subrc TYPE sy-subrc.
    DATA lv_cp    TYPE string.

    CLEAR: et_target, ev_reachable.

    lo_rfc = NEW zcl_scort_rfc_service( ).

    lo_rfc->get_remote_objects(
      EXPORTING
        iv_devclass = is_params-devclass
      IMPORTING
        et_objects  = et_target
        ev_subrc    = lv_subrc ).

    IF lv_subrc = 0.
      ev_reachable = abap_true.
    ELSE.
      ev_reachable = abap_false.
      RETURN.
    ENDIF.

    IF is_params-object_type IS NOT INITIAL.
      DELETE et_target WHERE object <> is_params-object_type.
    ENDIF.

    IF is_params-author IS NOT INITIAL.
      DELETE et_target WHERE author <> is_params-author.
    ENDIF.

    IF is_params-name_pattern IS NOT INITIAL.
      lv_cp = is_params-name_pattern.
      IF find( val = lv_cp sub = '*' ) < 0.
        lv_cp = |*{ lv_cp }*|.
      ENDIF.
      DELETE et_target WHERE NOT ( obj_name CP lv_cp ).
    ENDIF.

  ENDMETHOD.


  METHOD build_matrix.

    DATA ls_line     TYPE zi_scort_repository_sync.
    DATA lv_reachable TYPE abap_bool.
    DATA lt_source    TYPE zscort_t_rfc_object.
    DATA lt_target    TYPE zscort_t_rfc_object.

    io_repo->get_objects(
      EXPORTING
        iv_devclass     = is_params-devclass
        iv_object_type  = is_params-object_type
        iv_author       = is_params-author
        iv_name_pattern = is_params-name_pattern
      IMPORTING
        et_objects      = lt_source ).
    DELETE lt_source WHERE NOT ( devclass CP 'Y*' OR devclass CP 'Z*' ).

    call_target_objects(
      EXPORTING is_params    = is_params
      IMPORTING et_target    = lt_target
                ev_reachable = lv_reachable ).

    SORT lt_source BY object obj_name.
    SORT lt_target BY object obj_name.

    LOOP AT lt_source INTO DATA(ls_src).
      CLEAR ls_line.
      ls_line-objecttype = ls_src-object.
      ls_line-objectname = ls_src-obj_name.
      ls_line-devclass   = ls_src-devclass.
      ls_line-author      = ls_src-author.

      READ TABLE lt_target INTO DATA(ls_tgt)
        WITH KEY object = ls_src-object obj_name = ls_src-obj_name
        BINARY SEARCH.

      IF lv_reachable = abap_false.
        ls_line-syncstatus     = 'TARGET_UNREACHABLE'.
        ls_line-syncstatustext = 'Target system unreachable (RFC failed)'.
      ELSEIF sy-subrc = 0.
        ls_line-syncstatus     = 'IN_BOTH'.
        ls_line-syncstatustext = 'In both systems'.
      ELSE.
        ls_line-syncstatus     = 'SOURCE_ONLY'.
        ls_line-syncstatustext = 'Only in Source (S40)'.
      ENDIF.

      APPEND ls_line TO rt_result.
    ENDLOOP.

    IF lv_reachable = abap_true.
      LOOP AT lt_target INTO DATA(ls_tgt2).
        READ TABLE lt_source TRANSPORTING NO FIELDS
          WITH KEY object = ls_tgt2-object obj_name = ls_tgt2-obj_name
          BINARY SEARCH.
        CHECK sy-subrc <> 0.

        CLEAR ls_line.
        ls_line-objecttype     = ls_tgt2-object.
        ls_line-objectname     = ls_tgt2-obj_name.
        ls_line-devclass       = ls_tgt2-devclass.
        ls_line-author         = ls_tgt2-author.
        ls_line-syncstatus     = 'TARGET_ONLY'.
        ls_line-syncstatustext = 'Only in Target (S35)'.
        APPEND ls_line TO rt_result.
      ENDLOOP.
    ENDIF.

    SORT rt_result BY objecttype objectname.

  ENDMETHOD.


  METHOD if_rap_query_provider~select.

    DATA lt_all    TYPE tt_sync_result.
    DATA lt_page   TYPE tt_sync_result.
    DATA lt_result TYPE tt_sync_result.
    DATA ls_line   TYPE zi_scort_repository_sync.
    DATA ls_params TYPE ty_query_params.
    DATA lv_skip   TYPE i.
    DATA lv_top    TYPE i.

    DATA lo_repo   TYPE REF TO zcl_scort_repository.
    DATA lo_paging TYPE REF TO if_rap_query_paging.

    lo_repo   = NEW zcl_scort_repository( ).
    ls_params = parse_filter( io_request ).

    lt_all = build_matrix(
      io_repo   = lo_repo
      is_params = ls_params
    ).

    lo_paging = io_request->get_paging( ).
    IF lo_paging IS BOUND.
      lv_skip = lo_paging->get_offset( ).
      lv_top  = lo_paging->get_page_size( ).
      IF lv_top < 0.
        CLEAR lv_top.
      ENDIF.
    ENDIF.

    IF lv_top > 0.
      LOOP AT lt_all INTO ls_line FROM lv_skip + 1 TO lv_skip + lv_top.
        APPEND ls_line TO lt_page.
      ENDLOOP.
      lt_result = lt_page.
    ELSE.
      lt_result = lt_all.
    ENDIF.

    IF io_request->is_data_requested( ).
      io_response->set_data( lt_result ).
    ENDIF.

    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( CONV int8( lines( lt_all ) ) ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
