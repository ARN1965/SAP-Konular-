@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'SAT - SAS raporu (açık ve kapalı)'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZC_SAS_RAPOR
  as select from ekpo
    inner join      ekko on ekko.ebeln = ekpo.ebeln
    left outer join eban on  eban.banfn = ekpo.banfn
                         and eban.bnfpo = ekpo.bnfpo
    left outer join ZI_SAS_EKBE_OZET as ozet on  ozet.ebeln = ekpo.ebeln
                                              and ozet.ebelp = ekpo.ebelp
    left outer join makt on  makt.matnr = ekpo.matnr
                         and makt.spras = $session.system_language
{
  key ekpo.ebeln                  as SasNo,
  key ekpo.ebelp                  as SasKalem,

      ekpo.banfn                  as SatNo,
      ekpo.bnfpo                  as SatKalem,
      ekpo.matnr                  as Malzeme,
      // Tanım yoksa EKPO-TXZ01 kullanılır
      coalesce( makt.maktx, ekpo.txz01 ) as MalzemeTanimi,

      // SAT miktarı ve tutarı
      eban.meins                  as SatBirim,
      @Semantics.quantity.unitOfMeasure: 'SatBirim'
      eban.menge                  as SatMiktar,
      eban.waers                  as SatParaBirimi,
      @Semantics.amount.currencyCode: 'SatParaBirimi'
      eban.rlwrt                  as SatTutar,

      // SAS miktarı ve tutarı
      ekpo.meins                  as SasBirim,
      @Semantics.quantity.unitOfMeasure: 'SasBirim'
      ekpo.menge                  as SasMiktar,
      ekko.waers                  as ParaBirimi,
      @Semantics.amount.currencyCode: 'ParaBirimi'
      ekpo.netwr                  as SasTutar,

      // Tarihler
      eban.frgdt                  as SatOnayTarihi,
      ekko.aedat                  as SasYaratmaTarihi,
      case when eban.frgdt is null or eban.frgdt = '00000000'
           then cast( null as abap.int4 )
           else dats_days_between( eban.frgdt, ekko.aedat ) end as GunFarki,

      // Göstergeler
      case when ozet.mal_girisi_adet > 0 then 'X' else '' end as MalGirisiYapildi,
      case when ozet.fatura_adet > 0     then 'X' else '' end as FaturaGirisiYapildi,

      // Fatura tutarı: belge para birimi ve TRY
      @Semantics.amount.currencyCode: 'ParaBirimi'
      ozet.fatura_tutar_belge_pb  as FaturaTutarBelgePB,
      @Semantics.amount.currencyCode: 'FaturaParaBirimiTRY'
      ozet.fatura_tutar_try       as FaturaTutarTRY,
      cast( 'TRY' as abap.cuky )  as FaturaParaBirimiTRY,

      // Kontrol kodu (varsayım: EKPO-STEUC)
      ekpo.steuc                  as KontrolKodu,

      ekpo.loekz                  as SilmeGostergesi,
      ekpo.elikz                  as TeslimTamamlandi
}
