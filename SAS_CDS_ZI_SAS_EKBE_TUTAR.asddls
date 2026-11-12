@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'SAS geçmişi - satır bazında TRY ve kontrol kodu PB dönüşümü'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_SAS_EKBE_TUTAR
  as select from ekbe
    inner join      ekpo               on  ekpo.ebeln = ekbe.ebeln
                                       and ekpo.ebelp = ekbe.ebelp
    left outer join ZI_SAS_KOKRS as ko on  ko.Bukrs = ekpo.bukrs
{
  key ekbe.ebeln,
  key ekbe.ebelp,
  key ekbe.zekkn,
  key ekbe.vgabe,
  key ekbe.gjahr,
  key ekbe.belnr,
  key ekbe.buzei,
      ekbe.bewtp,
      ekbe.waers,
      ko.KokrsWaers                  as kokrs_pb,

      // Borç (S) pozitif, alacak (H) negatif işaretlenir
      @Semantics.amount.currencyCode: 'waers'
      case ekbe.shkzg when 'H' then cast( 0 as abap.curr(13,2) ) - ekbe.wrbtr else ekbe.wrbtr end as tutar_belge_pb,

      // Belge para birimi -> TRY (kur tipi M, kur tarihi BUDAT)
      @Semantics.amount.currencyCode: 'try_pb'
      currency_conversion(
        amount             => case ekbe.shkzg when 'H' then cast( 0 as abap.curr(13,2) ) - ekbe.wrbtr else ekbe.wrbtr end,
        source_currency    => ekbe.waers,
        target_currency    => cast( 'TRY' as abap.cuky ),
        exchange_rate_date => ekbe.budat,
        exchange_rate_type => 'M',
        error_handling     => 'SET_TO_NULL'
      ) as tutar_try,

      // Belge para birimi -> controlling area para birimi (USD)
      @Semantics.amount.currencyCode: 'kokrs_pb'
      currency_conversion(
        amount             => case ekbe.shkzg when 'H' then cast( 0 as abap.curr(13,2) ) - ekbe.wrbtr else ekbe.wrbtr end,
        source_currency    => ekbe.waers,
        target_currency    => ko.KokrsWaers,
        exchange_rate_date => ekbe.budat,
        exchange_rate_type => 'M',
        error_handling     => 'SET_TO_NULL'
      ) as tutar_kokrs,

      cast( 'TRY' as abap.cuky ) as try_pb
}
where
     ekbe.bewtp = 'E'   // mal girişi
  or ekbe.bewtp = 'Q'   // fatura girişi
