# SAT – SAS CDS Raporu

Açık ve kapalı tüm SAS kalemlerini SAT bilgileri, mal girişi/fatura durumu ve fatura tutarı (TRY + belge para birimi) ile listeler.
Dosyalar `SAS_CDS_` önekiyle kökte durur; istenirse bir klasöre taşınabilir.

| Dosya | Açıklama |
|---|---|
| `SAS_CDS_ZI_SAS_KOKRS.asddls` | Şirket kodu → Controlling Area ve para birimi (TKA02/TKA01) |
| `SAS_CDS_ZI_SAS_EKBE_TUTAR.asddls` | EKBE (E/Q) satırları, işaretli tutar, `currency_conversion` ile TRY ve KOKRS para birimi |
| `SAS_CDS_ZI_SAS_EKBE_OZET.asddls` | Kalem bazında mal girişi/fatura adedi ve fatura toplamları (aggregate) |
| `SAS_CDS_ZC_SAS_RAPOR.asddls` | Ana rapor view'i (EKPO, EKKO, EBAN, MAKT + özet) |
| `SAS_CDS_ALV.abap` | Basit ALV raporu (ZSAS_RAPOR_ALV) |

Aktivasyon sırası: KOKRS → TUTAR → OZET → RAPOR. View adları (ZI_/ZC_) dosya adlarından bağımsızdır.

## Varsayımlar
- **S/4HANA 2023 (S4CORE 108, SAP_BASIS 758):** `I_*API01` view'ları sistemde yok; bu yüzden **doğrudan tablolardan** (EKPO, EKKO, EBAN, EKBE, MAKT) okunur. ABAP CDS view entity, `currency_conversion`, `dats_days_between` kullanılır.
- **SAT onay tarihi:** `EBAN-FRGDT`; yoksa gün farkı NULL.
- **SAS yaratma tarihi:** `EKKO-AEDAT`. **Gün farkı** = SAS yaratma − SAT onay (negatif olabilir).
- **SAT bağlantısı:** `EKPO-BANFN/BNFPO` (SAT'sız SAS de listelenir).
- **Mal girişi:** EKBE `BEWTP='E'` varsa `X`. **Fatura girişi:** `BEWTP='Q'` varsa `X`; iptaller (`SHKZG='H'`) negatif.
- **Fatura tutarı:** `EKBE-WRBTR`; TRY için kur tipi `M`, kur tarihi `BUDAT`, kur yoksa NULL.
- **Kontrol kodu:** CO modülündeki Controlling Area (`KOKRS`). Şirket kodundan bulunur: `EKPO-BUKRS` → `TKA02` (GSBER boş kayıt) → `TKA01` (`KOKRS`, `WAERS`). Kontrol kodu para birimi `TKA01-WAERS` (USD) → `KontrolKoduParaBirimi`. Eşleme `ZI_SAS_KOKRS` view'inde; şirket kodu başına GSBER boş tek kayıt beklenir (yoksa KOKRS boş kalır).
- **Fatura tutarı (kontrol kodu PB):** `EKBE-WRBTR` belge para biriminden `TKA01-WAERS`'a `currency_conversion` ile çevrilir (`FaturaTutarKontrolKoduPB`; kur tipi `M`, kur tarihi `BUDAT`, kur yoksa NULL). TRY alanı (`FaturaTutarTRY`) korunur.
- **Para birimi:** `EKKO-WAERS`; SAT tutarı `EBAN-RLWRT`, para birimi `EBAN-WAERS`.
- **Açık/kapalı:** filtre yok; `TeslimTamamlandi` (ELIKZ) ve `SilmeGostergesi` (LOEKZ) ile ayrışır.
- **Performans:** EKBE toplamları ve TRY dönüşümü ayrı aggregate view'da (`ZI_SAS_EKBE_OZET`) kalem bazında önceden hesaplanır; ana view'de 5 join vardır (KOKRS eşlemesi anahtar erişimlidir). Rapora SAS no/tarih filtresi verin.
- Yetki kontrolü yok (`#NOT_REQUIRED`); kod bir sistemde derlenmedi.
