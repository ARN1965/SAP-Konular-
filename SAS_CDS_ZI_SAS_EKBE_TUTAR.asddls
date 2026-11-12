@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'SAS geçmişi - satır bazında TRY dönüşümü'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_SAS_EKBE_TUTAR
  as select from I_PurchaseOrderHistoryAPI01 as hist
{
  key hist.PurchasingHistoryDocumentType     as HistTipi,   // BEWTP: E mal girişi, Q fatura
  key hist.PurchasingHistoryDocumentYear     as HistYil,
  key hist.PurchasingHistoryDocument         as HistBelge,
  key hist.PurchasingHistoryDocumentItem     as HistKalem,
  key hist.PurchasingHistoryCategory         as HistKategori,
  key hist.AccountAssignmentNumber           as HistHesapAtama,
  key hist.PurchaseOrder                     as SasNo,
  key hist.PurchaseOrderItem                 as SasKalem,

      hist.DocumentCurrency                  as BelgePB,

      // Borç (S) pozitif, alacak (H) negatif işaretlenir
      @Semantics.amount.currencyCode: 'BelgePB'
      case hist.DebitCreditCode
        when 'H' then cast( 0 as abap.curr(13,2) ) - hist.InvoiceAmountInFrgnCurrency
        else hist.InvoiceAmountInFrgnCurrency
      end                                    as TutarBelgePB,

      // Belge para birimi -> TRY, kur tarihi: kayıt tarihi
      @Semantics.amount.currencyCode: 'TryPB'
      currency_conversion(
        amount             => case hist.DebitCreditCode
                                when 'H' then cast( 0 as abap.curr(13,2) ) - hist.InvoiceAmountInFrgnCurrency
                                else hist.InvoiceAmountInFrgnCurrency
                              end,
        source_currency    => hist.DocumentCurrency,
        target_currency    => cast( 'TRY' as abap.cuky ),
        exchange_rate_date => hist.PostingDate,
        exchange_rate_type => 'M',
        error_handling     => 'SET_TO_NULL'
      )                                      as TutarTRY,

      cast( 'TRY' as abap.cuky )             as TryPB
}
where
     hist.PurchasingHistoryDocumentType = 'E'   // mal girişi
  or hist.PurchasingHistoryDocumentType = 'Q'   // fatura girişi
