@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'SAS geçmişi - satır bazında TRY dönüşümü'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_SAS_EKBE_TUTAR
  as select from ekbe
{
  key ebeln,
  key ebelp,
  key zekkn,
  key vgabe,
  key gjahr,
  key belnr,
  key buzei,
      bewtp,
      waers,

      // Borç (S) pozitif, alacak (H) negatif işaretlenir
      @Semantics.amount.currencyCode: 'waers'
      case shkzg when 'H' then cast( 0 as abap.curr(13,2) ) - wrbtr else wrbtr end as tutar_belge_pb,

      // Belge para birimi -> TRY, kur tarihi: kayıt tarihi (BUDAT)
      @Semantics.amount.currencyCode: 'try_pb'
      currency_conversion(
        amount             => case shkzg when 'H' then cast( 0 as abap.curr(13,2) ) - wrbtr else wrbtr end,
        source_currency    => waers,
        target_currency    => cast( 'TRY' as abap.cuky ),
        exchange_rate_date => budat,
        exchange_rate_type => 'M',
        error_handling     => 'SET_TO_NULL'
      ) as tutar_try,

      cast( 'TRY' as abap.cuky ) as try_pb
}
where
     bewtp = 'E'   // mal girişi
  or bewtp = 'Q'   // fatura girişi
