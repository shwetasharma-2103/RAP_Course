CLASS zcl_shw_rap_eml_pract DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_shw_rap_eml_pract IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.

*  Step 1: Read

*   READ ENTITIES OF zi_shw_rap_travel
*        ENTITY Travel
*            FROM VALUE #( ( TravelUuid = '00381EA0A983219E17000402C4C4AEFE' ) )
*
*   RESULT DATA(Travels).
*
*   out->write( Travels ).
*
*
*   READ ENTITIES OF zi_shw_rap_travel
*        ENTITY Travel
*           ALL FIELDS WITH VALUE #( ( TravelUuid = '00381EA0A983219E17000402C4C4AEFE' ) )
*
*   RESULT DATA(Travels1).
*
*   out->write( Travels1 ).
*
*
*      READ ENTITIES OF zi_shw_rap_travel
*        ENTITY Travel
*           FIELDS ( TravelId AgencyId )
*           WITH VALUE #( ( TravelUuid = '00381EA0A983219E17000402C4C4AEFE' ) )
*
*   RESULT DATA(Travels2).
*
*   out->write( Travels2 ).
*
** Step 2: Read with association
*
*    READ ENTITIES OF zi_shw_rap_travel
*        ENTITY Travel BY \_Booking
*            ALL FIELDS WITH VALUE #( ( TravelUuid = '00381EA0A983219E17000402C4C4AEFE' ) )
*    RESULT DATA(TravelBooking).
*
*    out->write( |Association| ).
*    out->write( TravelBooking ).

*    Step 3 Modify: Update the description of Travel Id

*    MODIFY ENTITIES OF zi_shw_rap_travel
*        ENTITY Travel
*        UPDATE
*        SET FIELDS WITH VALUE
*            #( ( TravelUuid = '00381EA0A983219E17000402C4C4AEFE'
*                 Description = 'Updated description' ) )
*      FAILED DATA(Failed)
*      REPORTED DATA(Reported).
*
*      COMMIT ENTITIES
*        RESPONSE OF zi_shw_rap_travel
*        FAILED DATA(CommitFailed)
*        REPORTED DATA(CommitReported).
*
*      out->write( |Updated| ).

*  Step 4: Modify Create

*    MODIFY ENTITIES OF zi_shw_rap_travel
*        ENTITY Travel
*            CREATE
*                SET FIELDS WITH VALUE
*                    #( ( %cid = 'My_Content_id1'
*                         AgencyID = '70012'
*                         CustomerId =  '14'
*                         BeginDate = cl_abap_context_info=>get_system_date( )
*                         EndDate = cl_abap_context_info=>get_system_date( ) + 10
*                         Description = 'EML Sample'
*
*                    ) )
*    MAPPED DATA(Mapped)
*    FAILED DATA(Failed)
*    REPORTED DATA(Reported).
*
*    COMMIT ENTITIES
*        RESPONSE OF zi_shw_rap_travel
*            FAILED DATA(CommitFailed)
*            REPORTED DATA(CommitReported).
*
*    out->write( 'Created' ).
*    out->write( Mapped-travel ).

*     Step 4: Modify Create with Association

    out->write( 'Start' ).

    MODIFY ENTITIES OF zi_shw_rap_travel
        ENTITY Travel
            CREATE
                SET FIELDS WITH VALUE
                    #( ( %cid = 'cid1'
*                         TravelID = '100001'
                         AgencyID = '70012'
                         CustomerId =  '14'
                         BeginDate = cl_abap_context_info=>get_system_date( )
                         EndDate = cl_abap_context_info=>get_system_date( ) + 10
                         Description = 'EML Sample1'

                    )
                    (
                         %cid = 'cid2'
*                         TravelID = '100002'
                         AgencyID = '70012'
                         CustomerId =  '14'
                         BeginDate = cl_abap_context_info=>get_system_date( )
                         EndDate = cl_abap_context_info=>get_system_date( ) + 10
                         Description = 'EML Sample2'

                    )
                    )
            CREATE BY \_Booking
                SET FIELDS WITH VALUE
                    #( ( %cid_ref = 'cid1'
                         %target = VALUE #( ( %cid = 'book1'
*                                              BookingID = '100001'
                                              BookingDate = cl_abap_context_info=>get_system_date( )
                                             )
*                                             ( %cid = 'book2'
**                                              BookingID = '100002'
*                                              BookingDate = cl_abap_context_info=>get_system_date( )
*                                             )
                                                )
                        )
                        ( %cid_ref = 'cid2'
                         %target = VALUE #( ( %cid = 'book3'
*                                              BookingID = '100003'
                                              BookingDate = cl_abap_context_info=>get_system_date( )
                                             )
                                             ( %cid = 'book4'
*                                              BookingID = '100004'
                                              BookingDate = cl_abap_context_info=>get_system_date( )
                                             )
                                                )
                        )



                        )

    MAPPED DATA(Mapped)
    FAILED DATA(Failed)
    REPORTED DATA(Reported).

    out->write( 'Created' ).
    out->write( Mapped-travel ).
    out->write( Mapped-booking ).

    COMMIT ENTITIES
        RESPONSE OF zi_shw_rap_travel
            FAILED DATA(CommitFailed)
            REPORTED DATA(CommitReported).

    out->write( 'Commited' ).



  ENDMETHOD.

ENDCLASS.
