CLASS zcl_shw_query_imp DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    interfaces if_oo_adt_classrun.
    interfaces if_rap_query_provider.

    types t_agency_range type range of ZZ_TRAVEL_AGENCY_ES5-AgencyId.
    types t_business_data type table of ZZ_TRAVEL_AGENCY_ES5.

    methods get_agencies
        importing
            filter_cond type if_rap_query_filter=>tt_name_range_pairs optional
            top type i optional
            skip type i optional
            is_data_req type abap_bool
            is_count_req type abap_bool
        exporting
            business_data type t_business_data
            count type int8
        raising
            /iwbep/cx_cp_remote
            /iwbep/cx_gateway
            cx_web_http_client_error
            cx_http_dest_provider_error.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_shw_query_imp IMPLEMENTATION.


  METHOD get_agencies.

    DATA: filter_factory   TYPE REF TO /iwbep/if_cp_filter_factory,
          filter_node      TYPE REF TO /iwbep/if_cp_filter_node,
          root_filter_node TYPE REF TO /iwbep/if_cp_filter_node.

    DATA: http_client        TYPE REF TO if_web_http_client,
          odata_client_proxy TYPE REF TO /iwbep/if_cp_client_proxy,
          read_list_request  TYPE REF TO /iwbep/if_cp_request_read_list,
          read_list_response TYPE REF TO /iwbep/if_cp_response_read_lst.

    DATA service_consumption_name TYPE cl_web_odata_client_factory=>ty_service_definition_name.


*In a non-Trial SAP Cloud Platform, ABAP Environment system one would leverage the destination service of the underlying Cloud Foundry Environment
* and one would use the statement cl_http_destination_provider=>create_by_cloud_destination to generate a http destination in the ABAP Environment system based on these settings.
*This sample code is available in Service consumption. copy from there.

*Since it is not possible to leverage the destination service in the trial systems, we will use the method create_by_http_destination which allows to create a http client object based on the target URL.
*Here we take the root URL https://sapes5.sapdevcenter.com of the ES5 system since the relative URL will be added when creating the OData client proxy.


    DATA(http_destination) = cl_http_destination_provider=>create_by_url( i_url = 'https://sapes5.sapdevcenter.com' ).
    http_client = cl_web_http_client_manager=>create_by_http_destination( i_destination = http_destination ).

    service_consumption_name = to_upper( 'ZSHW_RAP_AGENCY_ESS' ).

    odata_client_proxy = cl_web_odata_client_factory=>create_v2_remote_proxy(
      EXPORTING
        iv_service_definition_name = service_consumption_name
        io_http_client             = http_client
        iv_relative_service_root   = '/sap/opu/odata/sap/ZAGENCYCDS_SRV/' ).

    " Navigate to the resource and create a request for the read operation
    read_list_request = odata_client_proxy->create_resource_for_entity_set( 'Z_TRAVEL_AGENCY_ES5' )->create_request_for_read( ).

    " Create the filter tree
    filter_factory = read_list_request->create_filter_factory( ).
    LOOP AT  filter_cond  INTO DATA(filter_condition).
      filter_node  = filter_factory->create_by_range( iv_property_path     = filter_condition-name
                                                              it_range     = filter_condition-range ).
      IF root_filter_node IS INITIAL.
        root_filter_node = filter_node.
      ELSE.
        root_filter_node = root_filter_node->and( filter_node ).
      ENDIF.
    ENDLOOP.

    IF root_filter_node IS NOT INITIAL.
      read_list_request->set_filter( root_filter_node ).
    ENDIF.

    IF is_data_req = abap_true.
      read_list_request->set_skip( skip ).
      IF top > 0 .
        read_list_request->set_top( top ).
      ENDIF.
    ENDIF.

    IF is_count_req = abap_true.
      read_list_request->request_count(  ).
    ENDIF.

    IF is_data_req = abap_false.
      read_list_request->request_no_business_data(  ).
    ENDIF.

    " Execute the request and retrieve the business data and count if requested
    read_list_response = read_list_request->execute( ).
    IF is_data_req = abap_true.
      read_list_response->get_business_data( IMPORTING et_business_data = business_data ).
    ENDIF.
    IF is_count_req = abap_true.
      count = read_list_response->get_count(  ).
    ENDIF.



  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    data business_data type t_business_data.
    data count type int8.
    data filter_conditions type if_rap_query_filter=>tt_name_range_pairs.
    data ranges_tables type if_rap_query_filter=>tt_range_option.

    ranges_tables = value #( ( sign = 'I' option = 'GE' low = '070015' ) ).
    filter_conditions = value #( ( name = 'AGENCYID' range = ranges_tables ) ).

    try.
        get_agencies(
            exporting
                filter_cond = filter_conditions
                top = 3
                skip = 1
                is_count_req = abap_true
                is_data_req = abap_true
             importing
                business_data = business_data
                count = count
        ).
       out->write( |Total no of records = { count }| ).
       out->write( business_data ).
    catch cx_root into data(exception).
        out->write( cl_message_helper=>get_latest_t100_exception( exception )->if_message~get_longtext( ) ).
    endtry.



  ENDMETHOD.

  METHOD if_rap_query_provider~select.

    DATA business_data TYPE t_business_data.
*Using the method get_paging() we can find out whether client side paging was requested with the incoming OData call.
    DATA(top)     = io_request->get_paging( )->get_page_size( ).
    DATA(skip)    = io_request->get_paging( )->get_offset( ).
*Get the list of requested field from odata request as well as sort order
    DATA(requested_fields)  = io_request->get_requested_elements( ).
    DATA(sort_order)    = io_request->get_sort_elements( ).
    DATA count TYPE int8.
*Using the method get_filter() we can retrieve the filter that was used by the incoming OData request
*and by calling the method ->get_as_ranges( ) provided by the filter object we can retrieve the filter as ranges.

    TRY.
        DATA(filter_condition) = io_request->get_filter( )->get_as_ranges( ).
*call get_agencies which will actually call the remote odata service
        get_agencies(
                 EXPORTING
                   filter_cond        = filter_condition
                   top                = CONV i( top )
                   skip               = CONV i( skip )
                   is_data_req  = io_request->is_data_requested( )
                   is_count_req = io_request->is_total_numb_of_rec_requested(  )
                 IMPORTING
                   business_data  = business_data
                   count     = count
                 ) .

*If $count requested

        IF io_request->is_total_numb_of_rec_requested(  ).
          io_response->set_total_number_of_records( count ).
        ENDIF.
*        If business data is requested it is mandatory to add the retrieved data via the method set_data() .
*If in addition the number of of all entries of an entity is requested
*the number of entities being returned must be set via the method set_total_number_of_records().
        IF io_request->is_data_requested(  ).
          io_response->set_data( business_data ).
        ENDIF.

      CATCH cx_root INTO DATA(exception).
        DATA(exception_message) = cl_message_helper=>get_latest_t100_exception( exception )->if_message~get_longtext( ).
    ENDTRY.


  ENDMETHOD.

ENDCLASS.



