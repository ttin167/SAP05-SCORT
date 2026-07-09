

CLASS zcl_scort_statistics_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider .

  PRIVATE SECTION.
    TYPES tt_stat_result TYPE STANDARD TABLE OF zi_scort_repository_statistics WITH DEFAULT KEY .

    METHODS resolve_dimension
      IMPORTING
        io_request TYPE REF TO if_rap_query_request
      RETURNING
        VALUE(rv_dimension) TYPE string .

    METHODS map_type_label
      IMPORTING
        iv_type TYPE trobjtype
      RETURNING
        VALUE(rv_label) TYPE string .

    METHODS is_tracked_type
      IMPORTING
        iv_type TYPE trobjtype
      RETURNING
        VALUE(rv_tracked) TYPE abap_bool .

    METHODS is_custom_namespace
      IMPORTING
        iv_value TYPE string
      RETURNING
        VALUE(rv_custom) TYPE abap_bool .

    METHODS build_by_type
      IMPORTING
        io_repo TYPE REF TO zcl_scort_repository
      RETURNING
        VALUE(rt_result) TYPE tt_stat_result .

    METHODS build_by_package
      IMPORTING
        io_repo TYPE REF TO zcl_scort_repository
      RETURNING
        VALUE(rt_result) TYPE tt_stat_result .

    METHODS build_by_author
      IMPORTING
        io_repo TYPE REF TO zcl_scort_repository
      RETURNING
        VALUE(rt_result) TYPE tt_stat_result .

    METHODS build_overview
      IMPORTING
        io_repo TYPE REF TO zcl_scort_repository
      RETURNING
        VALUE(rt_result) TYPE tt_stat_result .

ENDCLASS.


CLASS zcl_scort_statistics_query IMPLEMENTATION.


  METHOD resolve_dimension.

    DATA lo_filter TYPE REF TO if_rap_query_filter.
    DATA lv_fname  TYPE string.

    rv_dimension = 'TYPE'. " mac dinh neu khong filter -> hien khoi Type

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
      CHECK lv_fname CS 'DIMENSION'.
      LOOP AT ls_pair-range INTO DATA(ls_r).
        IF ls_r-sign <> 'E' AND ls_r-low IS NOT INITIAL.
          rv_dimension = ls_r-low.
          TRANSLATE rv_dimension TO UPPER CASE.
          RETURN.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.


  METHOD map_type_label.

    CASE iv_type.
      WHEN 'CLAS'. rv_label = 'Classes'.
      WHEN 'PROG'. rv_label = 'Reports'.
      WHEN 'TABL'. rv_label = 'Tables'.
      WHEN 'DDLS'. rv_label = 'CDS Views'.
      WHEN 'FUGR'. rv_label = 'Function Groups'.
      WHEN 'DOMA'. rv_label = 'Domains'.
      WHEN 'DTEL'. rv_label = 'Data Elements'.
      WHEN 'TRAN'. rv_label = 'Transactions'.
      WHEN OTHERS. rv_label = CONV string( iv_type ).
    ENDCASE.

  ENDMETHOD.


  METHOD is_tracked_type.

    CASE iv_type.
      WHEN 'CLAS' OR 'PROG' OR 'TABL' OR 'DDLS' OR 'FUGR' OR 'DOMA' OR 'DTEL' OR 'TRAN'.
        rv_tracked = abap_true.
      WHEN OTHERS.
        rv_tracked = abap_false.
    ENDCASE.

  ENDMETHOD.


  METHOD is_custom_namespace.

    DATA lv_val TYPE string.

    lv_val = iv_value.
    CONDENSE lv_val.
    CHECK strlen( lv_val ) > 0.

    IF lv_val(1) = 'Y' OR lv_val(1) = 'Z'.
      rv_custom = abap_true.
    ENDIF.

  ENDMETHOD.


  METHOD build_by_type.


    DATA ls_line TYPE zi_scort_repository_statistics.
    DATA lt_all  TYPE zscort_t_rfc_object.

    io_repo->get_objects(
      EXPORTING iv_devclass = space
      IMPORTING et_objects  = lt_all ).

    LOOP AT lt_all INTO DATA(ls_obj).
      CHECK is_custom_namespace( CONV string( ls_obj-devclass ) ) = abap_true.
      CHECK is_tracked_type( ls_obj-object ) = abap_true.
      CLEAR ls_line.
      ls_line-dimension   = 'TYPE'.
      ls_line-groupkey    = ls_obj-object.
      ls_line-grouplabel  = map_type_label( ls_obj-object ).
      ls_line-objectcount = 1.
      COLLECT ls_line INTO rt_result.
    ENDLOOP.

    SORT rt_result BY objectcount DESCENDING.

  ENDMETHOD.


  METHOD build_by_package.

    DATA ls_line TYPE zi_scort_repository_statistics.
    DATA lt_all  TYPE zscort_t_rfc_object.

    io_repo->get_objects(
      EXPORTING iv_devclass = space
      IMPORTING et_objects  = lt_all ).

    LOOP AT lt_all INTO DATA(ls_obj).
      CHECK ls_obj-devclass IS NOT INITIAL.
      CHECK is_custom_namespace( CONV string( ls_obj-devclass ) ) = abap_true.
      CLEAR ls_line.
      ls_line-dimension   = 'PACKAGE'.
      ls_line-groupkey    = ls_obj-devclass.
      ls_line-grouplabel  = ls_obj-devclass.
      ls_line-objectcount = 1.
      COLLECT ls_line INTO rt_result.
    ENDLOOP.

    SORT rt_result BY objectcount DESCENDING.

  ENDMETHOD.


  METHOD build_by_author.

    DATA ls_line TYPE zi_scort_repository_statistics.
    DATA lt_all  TYPE zscort_t_rfc_object.

    io_repo->get_objects(
      EXPORTING iv_devclass = space
      IMPORTING et_objects  = lt_all ).

    LOOP AT lt_all INTO DATA(ls_obj).
      CHECK ls_obj-author IS NOT INITIAL.
      CHECK is_custom_namespace( CONV string( ls_obj-devclass ) ) = abap_true.
      CLEAR ls_line.
      ls_line-dimension   = 'AUTHOR'.
      ls_line-groupkey    = ls_obj-author.
      ls_line-grouplabel  = ls_obj-author.
      ls_line-objectcount = 1.
      COLLECT ls_line INTO rt_result.
    ENDLOOP.

    SORT rt_result BY objectcount DESCENDING.

  ENDMETHOD.


  METHOD build_overview.

    DATA ls_line TYPE zi_scort_repository_statistics.
    DATA lt_all  TYPE zscort_t_rfc_object.
    DATA lt_pkg  TYPE STANDARD TABLE OF string.
    DATA lt_auth TYPE STANDARD TABLE OF string.

    io_repo->get_objects(
      EXPORTING iv_devclass = space
      IMPORTING et_objects  = lt_all ).
    DELETE lt_all WHERE NOT ( devclass CP 'Y*' OR devclass CP 'Z*' ).

    LOOP AT lt_all INTO DATA(ls_obj).
      IF ls_obj-devclass IS NOT INITIAL.
        APPEND CONV string( ls_obj-devclass ) TO lt_pkg.
      ENDIF.
      IF ls_obj-author IS NOT INITIAL.
        APPEND CONV string( ls_obj-author ) TO lt_auth.
      ENDIF.
    ENDLOOP.

    SORT lt_pkg.
    DELETE ADJACENT DUPLICATES FROM lt_pkg.
    SORT lt_auth.
    DELETE ADJACENT DUPLICATES FROM lt_auth.

    CLEAR ls_line.
    ls_line-dimension   = 'OVERVIEW'.
    ls_line-groupkey    = 'TOTAL_OBJECTS'.
    ls_line-grouplabel  = 'Total Repository Objects'.
    ls_line-objectcount = lines( lt_all ).
    APPEND ls_line TO rt_result.

    CLEAR ls_line.
    ls_line-dimension   = 'OVERVIEW'.
    ls_line-groupkey    = 'TOTAL_PACKAGES'.
    ls_line-grouplabel  = 'Total Packages'.
    ls_line-objectcount = lines( lt_pkg ).
    APPEND ls_line TO rt_result.

    CLEAR ls_line.
    ls_line-dimension   = 'OVERVIEW'.
    ls_line-groupkey    = 'TOTAL_DEVELOPERS'.
    ls_line-grouplabel  = 'Total Developers'.
    ls_line-objectcount = lines( lt_auth ).
    APPEND ls_line TO rt_result.

  ENDMETHOD.


  METHOD if_rap_query_provider~select.

    DATA lt_all    TYPE tt_stat_result.
    DATA lt_page   TYPE tt_stat_result.
    DATA lt_result TYPE tt_stat_result.
    DATA ls_line   TYPE zi_scort_repository_statistics.
    DATA lv_skip   TYPE i.
    DATA lv_top    TYPE i.
    DATA lv_dim    TYPE string.

    DATA lo_repo   TYPE REF TO zcl_scort_repository.
    DATA lo_paging TYPE REF TO if_rap_query_paging.

    lo_repo = NEW zcl_scort_repository( ).
    lv_dim  = resolve_dimension( io_request ).

    CASE lv_dim.
      WHEN 'PACKAGE'.
        lt_all = build_by_package( lo_repo ).
      WHEN 'AUTHOR'.
        lt_all = build_by_author( lo_repo ).
      WHEN 'OVERVIEW'.
        lt_all = build_overview( lo_repo ).
      WHEN OTHERS.
        lt_all = build_by_type( lo_repo ).
    ENDCASE.

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
