# Relatorio de Alinhamento de Traducoes

**Status**: Atualizado
**Ultima revisao**: 2026-06-15

Total de chaves no template ingles: **1280**

| Idioma | Chaves traduzidas | Cobertura | Chaves faltantes | Chaves extras |
|--------|-------------------|-----------|------------------|---------------|
| AR | 1280 | 100.0% | 0 | 0 |
| BN | 1280 | 100.0% | 0 | 0 |
| DE | 1280 | 100.0% | 0 | 0 |
| ES | 1280 | 100.0% | 0 | 0 |
| FR | 1280 | 100.0% | 0 | 0 |
| HI | 1280 | 100.0% | 0 | 0 |
| IT | 1280 | 100.0% | 0 | 0 |
| JA | 1280 | 100.0% | 0 | 0 |
| KO | 1280 | 100.0% | 0 | 0 |
| PT | 1280 | 100.0% | 0 | 0 |
| RU | 1280 | 100.0% | 0 | 0 |
| ZH | 1280 | 100.0% | 0 | 0 |
| UR | 1280 | 100.0% | 0 | 0 |

## Observacoes

- Todos os ARB nao ingleses estao alinhados com `app_en.arb`.
- Nao ha chaves faltantes ou extras nos idiomas suportados.
- Nao rode `dart tool/i18n/generate_arb.dart` globalmente para atualizar este relatorio; esse fluxo e destrutivo quando `arb_strings.dart` nao esta sincronizado com todas as chaves existentes.
- Para novas traducoes, use o fluxo seguro do projeto: gerar payload de chaves faltantes, traduzir, e mesclar de volta com `tool/i18n/merge_back_translations.py`.
