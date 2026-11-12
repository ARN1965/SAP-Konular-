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

Aktivasyon sırası: KOKRS → TUTAR → OZET → RAPOR → ALV. `SAS_CDS_ALV.abap` (ZSAS_RAPOR_ALV) `ZC_SAS_RAPOR` aktif olmadan derlenmez. View adları (ZI_/ZC_) dosya adlarından bağımsızdır.

## Varsayımlar
- **S/4HANA 2023 (S4CORE 108, SAP_BASIS 758):** `I_*API01` view'ları sistemde yok; bu yüzden **doğrudan tablolardan** (EKPO, EKKO, EBAN, EKBE, MAKT) okunur. ABAP CDS view entity, `currency_conversion`, `dats_days_between` kullanılır.
- **SAT onay tarihi:** `EBAN-FRGDT`; yoksa gün farkı NULL.
- **SAS yaratma tarihi:** `EKKO-AEDAT`. **Gün farkı** = SAS yaratma − SAT onay (negatif olabilir).
- **SAT bağlantısı:** `EKPO-BANFN/BNFPO` (SAT'sız SAS de listelenir).
- **Mal girişi:** EKBE `BEWTP='E'` net adedi (S:+1, H:−1) > 0 ise `X`. **Fatura girişi:** `BEWTP='Q'` net adedi > 0 ise `X`; tamamen iptal edilenler işaretlenmez.
- **Fatura tutarı:** `EKBE-WRBTR` (iptaller negatif); fatura para birimi SAS para biriminden farklı olabileceği için tutar önce `EKKO-WAERS`'a çevrilir (`FaturaTutarBelgePB`, para birimi `ParaBirimi`). Böylece özet view'da kalem başına tek satır oluşur (key: EBELN, EBELP). TRY ve kontrol kodu PB tutarları ayrıca çevrilir.
- **Kontrol kodu:** CO modülündeki Controlling Area (`KOKRS`). Şirket kodundan bulunur: `EKPO-BUKRS` → `TKA02` (GSBER boş kayıt) → `TKA01` (`KOKRS`, `WAERS`). Kontrol kodu para birimi `TKA01-WAERS` (USD) → `KontrolKoduParaBirimi`. Eşleme `ZI_SAS_KOKRS` view'inde; şirket kodu başına GSBER boş tek kayıt beklenir (yoksa KOKRS boş kalır).
- **Kur tarihi ve tipi:** fatura belge tarihi `RBKP-BLDAT` (EKBE `BELNR/GJAHR` ile left outer join; yalnızca `BEWTP='Q'` için kullanılır, mal girişi `E` satırlarında `EKBE-BUDAT`; RBKP bulunamazsa da `BUDAT`), kur tipi `M`. Kur bulunamazsa veya TKA02 eşlemesi yoksa (hedef para birimi NULL) `error_handling => 'SET_TO_NULL'` ile tutar NULL döner.
- **Muhasebe belgesi (ACDOCA) değerlendirmesi:** Tercih edilen yol ACDOCA'dan hazır tutarlar (HSL/KSL) idi, ancak kullanılmadı: bir fatura kaleminin ACDOCA'da birden çok satırı vardır (gider, GR/IR, vergi, satıcı) ve hangi satırın "fatura tutarı" olduğunu hesap/kayıt mantığı olmadan güvenle seçmek mümkün değildir (çift sayım riski); ayrıca ACDOCA'daki ikinci/üçüncü para birimi controlling area para biriminin (USD) aynısı olmayabilir. Bu nedenle 2. seçenek uygulanmıştır: `RBKP-BLDAT` + `M` kuruyla `currency_conversion`. Mutabakat için ACDOCA (`AWTYP='RMRP'`, `AWREF`=BELNR, `AWORG`=GJAHR) elle karşılaştırılabilir.
- **Fatura tutarı (kontrol kodu PB):** `EKBE-WRBTR` belge para biriminden `TKA01-WAERS`'a `currency_conversion` ile çevrilir (`FaturaTutarKontrolKoduPB`). TRY alanı (`FaturaTutarTRY`) korunur; ikisi de aggregate view'da hesaplanır.
- **Para birimi:** `EKKO-WAERS`; SAT tutarı `EBAN-RLWRT`, para birimi `EBAN-WAERS`.
- **Açık/kapalı:** filtre yok; `TeslimTamamlandi` (ELIKZ) ve `SilmeGostergesi` (LOEKZ) ile ayrışır.
- **Performans:** EKBE toplamları ve TRY dönüşümü ayrı aggregate view'da (`ZI_SAS_EKBE_OZET`) kalem bazında önceden hesaplanır; ana view'de 5 join vardır (KOKRS eşlemesi anahtar erişimlidir). Rapora SAS no/tarih filtresi verin.
- **Seçim ekranı (ALV):** SAS no, SAS yaratma tarihi ve çoklu üretim yeri (`SO_WERKS` → `EKPO-WERKS`, `ZC_SAS_RAPOR.Uretimyeri`).
- Yetki kontrolü yok (`#NOT_REQUIRED`); kod bir sistemde derlenmedi.

## Test ön yüzü ve hayali veri
- `SAS_CDS_TEST_ON_YUZ.html`: sunucusuz, tarayıcıda açılan SAP ALV benzeri ön yüz (F8 çalıştır, F3 geri, F12 iptal; SAS no/tarih/çoklu üretim yeri seçimi, sıralama, filtre, toplam, alt toplam, CSV).
- `SAS_CDS_TEST_VERI.csv`: 150 satırlık hayali veri (`;` ayraçlı, ZC_SAS_RAPOR kolonlarıyla aynı); aynı veri HTML'e gömülüdür. Kur olmayan satırlarda TRY/USD tutarı boştur.

## Yeni tarih alanları
- `SatYaratmaTarihi` = `EBAN-ERDAT` (SAT kaydının yaratıldığı tarih; `BADAT` talep tarihi olduğundan kullanılmadı). `SatYaratmaOnayGunFarki` = `EBAN-FRGDT` − `EBAN-ERDAT`.
- `GunFarki` yeniden adlandırıldı: `SatOnaySasYaratmaGunFarki` (SAT onay → SAS yaratma).
- `SasOnayTarihi` = `EKKO-FRGDT`; onay stratejisi yoksa/onaylanmadıysa boştur. `SasYaratmaOnayGunFarki` = `EKKO-FRGDT` − `EKKO-AEDAT`.
- Boş/`00000000` tarihler NULL sayılır; farklar `dats_days_between` ile hesaplanır, negatif fark olduğu gibi gösterilir.
- Test verisi/ön yüz yeni kolonlarla güncellendi (bazı SAT ve SAS'lar onaysız).
