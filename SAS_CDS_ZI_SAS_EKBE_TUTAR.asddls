@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'SAS geçmişi - satır bazında PO PB, TRY ve kontrol kodu PB tutarı'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_SAS_EKBE_TUTAR
  as select from ekbe
    inner join      ekpo               on  ekpo.ebeln = ekbe.ebeln
                                       and ekpo.ebelp = ekbe.ebelp
    inner join      ekko               on  ekko.ebeln = ekbe.ebeln
    left outer join ZI_SAS_KOKRS as ko on  ko.Bukrs = ekpo.bukrs
    // Fatura belge tarihi (kur tarihi) için fatura başlığı; kullanımı bldat ifadesinde Q ile sınırlı
    left outer join rbkp               on  rbkp.belnr = ekbe.belnr
                                       and rbkp.gjahr = ekbe.gjahr
{
  key ekbe.ebeln,
  key ekbe.ebelp,
  key ekbe.zekkn,
  key ekbe.vgabe,
  key ekbe.gjahr,
  key ekbe.belnr,
  key ekbe.buzei,
      ekbe.bewtp,
      ekko.waers                     as po_pb,
      ko.KokrsWaers                  as kokrs_pb,

      // Net adet: borç (S) +1, alacak (H) -1 (iptaller dengelenir)
      case ekbe.shkzg when 'H' then -1 else 1 end as net_adet,

      // Fatura PB -> PO para birimi (aynı para biriminde tutar değişmez)
      @Semantics.amount.currencyCode: 'po_pb'
      currency_conversion(
        amount             => case ekbe.shkzg when 'H' then cast( 0 as abap.curr(13,2) ) - ekbe.wrbtr else ekbe.wrbtr end,
        source_currency    => ekbe.waers,
        target_currency    => ekko.waers,
        exchange_rate_date => coalesce( case ekbe.bewtp when 'Q' then rbkp.bldat else ekbe.budat end, ekbe.budat ),
        exchange_rate_type => 'M',
        error_handling     => 'SET_TO_NULL'
      ) as tutar_po_pb,

      // Fatura PB -> TRY (kur tipi M, kur tarihi: Q için RBKP-BLDAT, E için BUDAT)
      @Semantics.amount.currencyCode: 'try_pb'
      currency_conversion(
        amount             => case ekbe.shkzg when 'H' then cast( 0 as abap.curr(13,2) ) - ekbe.wrbtr else ekbe.wrbtr end,
        source_currency    => ekbe.waers,
        target_currency    => cast( 'TRY' as abap.cuky ),
        exchange_rate_date => coalesce( case ekbe.bewtp when 'Q' then rbkp.bldat else ekbe.budat end, ekbe.budat ),
        exchange_rate_type => 'M',
        error_handling     => 'SET_TO_NULL'
      ) as tutar_try,

      // Fatura PB -> controlling area para birimi (USD); TKA02 eşlemesi yoksa NULL
      @Semantics.amount.currencyCode: 'kokrs_pb'
      currency_conversion(
        amount             => case ekbe.shkzg when 'H' then cast( 0 as abap.curr(13,2) ) - ekbe.wrbtr else ekbe.wrbtr end,
        source_currency    => ekbe.waers,
        target_currency    => ko.KokrsWaers,
        exchange_rate_date => coalesce( case ekbe.bewtp when 'Q' then rbkp.bldat else ekbe.budat end, ekbe.budat ),
        exchange_rate_type => 'M',
        error_handling     => 'SET_TO_NULL'
      ) as tutar_kokrs,

      cast( 'TRY' as abap.cuky ) as try_pb
}
where
     ekbe.bewtp = 'E'   // mal girişi
  or ekbe.bewtp = 'Q'   // fatura girişi
