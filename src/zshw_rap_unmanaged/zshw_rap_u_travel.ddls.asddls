@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'SHW RAP UNM Travel'
define root view entity ZSHW_RAP_U_TRAVEL as select from /dmo/travel
composition[0..*] of ZSHW_RAP_U_BOOKING as _Booking 
association [0..1] to /dmo/agency as _Agency on $projection.AgencyId = _Agency.agency_id
association [0..1] to /dmo/customer as _Customer on $projection.CustomerId = _Customer.customer_id
association [0..1] to I_Currency as _Currency on $projection.CurrencyCode = _Currency.Currency
{
      key travel_id as TravelId,
      agency_id as AgencyId,
      customer_id as CustomerId,
      begin_date as BeginDate,
      end_date as EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      booking_fee as BookingFee,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      total_price as TotalPrice,
      currency_code as CurrencyCode,
      description as Description,
      status as Status,
      @Semantics.user.createdBy: true
      createdby as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      createdat as CreatedAt,
      @Semantics.user.lastChangedBy: true
      lastchangedby as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      lastchangedat as LastChangedAt,
//      Expose associations
      _Booking,
      _Agency,
      _Customer,
      _Currency
}
