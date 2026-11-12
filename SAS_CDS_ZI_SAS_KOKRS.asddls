@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Şirket kodu - Controlling Area (kontrol kodu) ve para birimi'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_SAS_KOKRS
  as select from tka02
    inner join    tka01 on tka01.kokrs = tka02.kokrs
{
  key tka02.bukrs as Bukrs,
      tka02.kokrs as Kokrs,
      tka01.waers as KokrsWaers
}
// İş alanı (GSBER) boş kayıt; şirket kodu başına tek kayıt beklenir
where tka02.gsber = ''
