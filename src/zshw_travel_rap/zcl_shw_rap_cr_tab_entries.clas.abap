CLASS zcl_shw_rap_cr_tab_entries DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_shw_rap_cr_tab_entries IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.

*      Delete existing entries
    DELETE FROM zshw_rap_travel.
    DELETE FROM zshw_rap_travel.

*    insert travel demo data
    INSERT zshw_rap_travel FROM (
      SELECT
        FROM /dmo/travel
          FIELDS
            uuid(  ) AS travel_uuid,
            travel_id AS travel_id,
            agency_id AS agency_id,
            customer_id AS customer_id,
            begin_date AS begin_date,
            end_date AS end_date,
            booking_fee AS booking_fee,
            total_price AS total_price,
            currency_code AS currency_code,
            description AS description,
            CASE status
            WHEN 'B' THEN 'A'  "accepted
            WHEN 'X' THEN 'X'  "cancelled
            ELSE 'O'
            END
            AS overall_status,
            createdby AS created_by,
            createdat AS created_at,
            lastchangedby AS last_changed_by,
            lastchangedat AS last_changed_at
            ORDER BY travel_id UP TO 200 ROWS ).

    COMMIT WORK.

*     insert Booking demo data
    INSERT zshw_rap_booking FROM (
        SELECT
          FROM /dmo/booking AS booking
             JOIN zshw_rap_travel AS travel
                ON booking~travel_id = travel~travel_id
                FIELDS
                  uuid( ) AS booking_uuid,
                  travel~travel_uuid AS travel_uuid,
                  booking~booking_id AS booking_id,
                  booking~booking_date AS booking_date,
                  booking~customer_id AS customer_id,
                  booking~carrier_id AS carrier_id,
                  booking~connection_id AS connection_id,
                  booking~flight_date AS flight_date,
                  booking~flight_price AS flight_price,
                  booking~currency_code AS currency_code,
                  travel~created_by AS created_by,
                  travel~last_changed_by AS last_changed_by,
                  travel~last_changed_at AS last_changed_at ).

    COMMIT WORK.

    out->write( |Data loaded successfully into Travel and Booking| ).




  ENDMETHOD.

ENDCLASS.
