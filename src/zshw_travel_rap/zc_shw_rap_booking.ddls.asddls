@EndUserText.label: 'Consumption view for SHW RAP Booking'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
define view entity ZC_SHW_RAP_BOOKING
  as projection on ZI_SHW_RAP_BOOKING as Booking
{

  key BookingUuid,

      TravelUuid,

      @Search.defaultSearchElement: true
      BookingId,

      BookingDate,

      @Search.defaultSearchElement: true
      @ObjectModel.text.element: ['CustomerName']
      @Consumption.valueHelpDefinition: [{
                          entity: { name: '/DMO/I_CUSTOMER',
                                    element: 'CustomerID' } }]
      CustomerId,

      _Customer.LastName as CustomerName,

      @ObjectModel.text.element: ['CarrierName']
      @Consumption.valueHelpDefinition: [{
                          entity: { name: '/DMO/I_CARRIER',
                                    element: 'AirlineID' } }]
      CarrierId,

      _Carrier.Name      as CarrierName,

      @ObjectModel.text.element: ['CarrierName']
      @Consumption.valueHelpDefinition: [{
                          entity: { name: '/DMO/I_CARRIER',
                                    element: 'AirlineID' },
                          additionalBinding: [{ localElement: 'CarrierID', element: 'AirlineID' },
                                              { localElement: 'FlightDate', element: 'FlightDate, usage: #RESULT' },
                                              { localElement: 'FlightPrice', element: 'FlightPrice', usage: #RESULT },
                                              { localElement: 'CurrencyCode', element: 'CurrencyCode', usage: #RESULT}   
                                 ] }]
      ConnectionId,

      FlightDate,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      FlightPrice,

      @Consumption.valueHelpDefinition: [{
                         entity: { name: 'I_CURRENCY',
                                   element: 'CURRENCY' } }]
      @Semantics.currencyCode: true
      CurrencyCode,

      CreatedBy,

      LastChangedBy,

      LocalLastChangedAt,
      /* Associations */
      _Carrier ,
      _Connection,
      _Currency,
      _Customer,
      _Flight,
      _Travel : redirected to parent ZC_SHW_RAP_TRAVEL 
}
