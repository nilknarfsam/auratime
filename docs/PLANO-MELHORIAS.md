# Plano de melhorias e correções — AuraTime

> Levantamento feito em 24/08/2026 sobre `main`, na versão `0.2.1+4`, com Flutter 3.41.4 / Dart 3.11.1.
> `flutter analyze` e `flutter test` foram executados neste estado.

## Sumário

- [Estado atual](#estado-atual)
- [Bloqueador de publicação](#bloqueador-de-publicação)
- [Bugs de integridade](#bugs-de-integridade)
- [Lacunas de uso](#lacunas-de-uso)
- [Dívida técnica](#dívida-técnica)
- [Plano de execução](#plano-de-execução)
- [Ordem sugerida](#ordem-sugerida)

---

## Estado atual

| Verificação | Resultado |
| --- | --- |
| `flutter test` | 58 testes, todos passando |
| `flutter analyze` | nenhum issue |
| Tamanho de `lib/` | ~5.500 linhas |
| Alinhamento do `libisar.so` | **4 KB** — precisa ser 16 KB |

Pontos fortes que valem preservar nas mudanças abaixo:

- **Domínio isolado da UI.** `WorkScheduleEngine`, `DailyStatusEngine`, `WorkDayAccounting` e
  `InsightsEngine` são classes puras, sem dependência de Flutter. É o que permite testá-las sem
  emulador e o que sustenta os 58 testes.
- **Regra de negócio não trivial já modelada.** Turno que cruza a meia-noite, feriados por preset e
  por exceção, folga compensatória, troca de feriado e a distinção bruto/líquido do almoço estão
  todos cobertos por teste.
- **Backup com versionamento.** `BackupPayload` tem `backupVersion`, valida a origem do arquivo e
  faz upsert por data.
- **Cuidado real com render.** `RepaintBoundary`, `ValueNotifier` por revisão e um único `Timer` de
  30s isolado no bloco de métricas, em vez de `setState` na tela toda.
- **Assinatura e release configurados**, com `key.properties` fora do versionamento.

---

## Bloqueador de publicação

### B-01 — O binário do Isar é de 4 KB e o Play exige 16 KB

**Impede o envio ao Google Play hoje**, independente de qualquer outro item desta lista.

Os cabeçalhos ELF dos `.so` vendorizados mostram que os quatro segmentos `PT_LOAD` do `arm64-v8a`
têm `p_align = 0x1000` (4 KB). Desde 1º de novembro de 2025 o Google Play recusa apps e atualizações
com `targetSdk >= 35` que não suportem páginas de 16 KB — e o Flutter 3.41 usa `targetSdk 36` por
padrão. Em aparelhos com página de 16 KB a biblioteca não carrega.

**Onde:** `third_party/isar_flutter_libs/android/src/main/jniLibs/*/libisar.so`

**Correção:** migrar para o fork mantido — `isar_community`, `isar_community_generator` e
`isar_community_flutter_libs` (3.3.2), que tratam o caso de 16 KB desde a 3.2.0. É o mesmo formato
de arquivo de banco, então os dados existentes devem abrir normalmente — **validar com um banco real
antes de publicar**. A migração provavelmente elimina também o `dependency_overrides` e a pasta
`third_party/`, que existem só por causa do `compileSdk 30` do pacote original. Depois de trocar,
reconferir o alinhamento nos quatro ABIs antes de gerar o AAB.

Para conferir o alinhamento de um `.so` (PowerShell):

```powershell
$p='caminho\para\libisar.so'
$b=[System.IO.File]::ReadAllBytes($p)
$phoff=[BitConverter]::ToInt64($b,0x20)
$phentsize=[BitConverter]::ToUInt16($b,0x36)
$phnum=[BitConverter]::ToUInt16($b,0x38)
for($i=0;$i -lt $phnum;$i++){
  $o=$phoff+$i*$phentsize
  if([BitConverter]::ToUInt32($b,$o) -eq 1){
    "PT_LOAD align = 0x{0:X}" -f [BitConverter]::ToInt64($b,$o+48)
  }
}
```

Esperado após a migração: `0x4000` (16384).

---

## Bugs de integridade

Todos afetam dado gravado ou disponibilidade do app.

### B-02 — O widget da tela inicial bate ponto em folga e feriado

Existem dois conceitos de "tipo de dia" no projeto. O widget checa `record.dayType` — o campo
`DayType` persistido no Isar — mas **nada no app escreve nesse campo**, só a importação de backup.
Ele é sempre `regular`, então a guarda nunca dispara. O calendário de verdade vive em
`WorkScheduleEngine.getDayType`, que o widget não consulta.

Resultado: num domingo, feriado ou sábado ainda não classificado, o botão do widget grava a batida
enquanto a tela do app bloqueia o mesmo gesto. Como o dia esperado é zero, o tempo trabalhado entra
inteiro como saldo positivo, sem passar pela folha de classificação.

**Onde:** `lib/services/widget_service.dart:25`, `:64-69` · `lib/models/time_record.dart:8`

**Correção:** no `backgroundCallback`, consultar `WorkScheduleEngine.getShiftForDate(hoje)` e não
registrar quando for `null`. Atenção a um detalhe fácil de perder: o callback roda em outro isolate
e nunca chama `AppSettingsService.initialize()`, então lá `AppSettingsService.current` são os padrões
de fábrica — as regras de calendário do usuário precisam ser carregadas antes de decidir.

### B-03 — Corrigir a saída zera o dia no segundo turno

Ao editar um horário pelo card, o app monta o `DateTime` sempre com a data de hoje. No segundo turno
comercial (16:48 → 02:01) a saída cai no dia seguinte, então a correção vira "hoje às 02:01" —
anterior à entrada. `totalWorkedHours` exige `exit.isAfter(entry)` e devolve zero, e o dia inteiro
vira saldo negativo cheio.

A batida automática acerta isso (grava o instante real), então o bug só aparece quando a pessoa vai
justamente corrigir um erro.

**Onde:** `lib/screens/dashboard_screen.dart:511-518` · `lib/models/time_record.dart:36`

**Correção:** derivar a data-base do turno — se `shift.isOvernight` e o horário escolhido for menor
que o de entrada, somar um dia — e validar `exit > entry` antes de salvar, com mensagem explicando o
que ficou inválido em vez de gravar zero em silêncio.

### B-04 — Falha ao abrir o banco derruba o app na tela branca

`main()` faz `Future.wait` com a inicialização do Isar e das preferências sem nenhum tratamento,
antes de `runApp`. Se o banco não abrir — arquivo corrompido, storage cheio, lock de outro processo
— a exceção sobe e o usuário vê tela branca, sem mensagem e sem caminho de recuperação. Justamente o
cenário em que ele mais precisaria chegar ao botão de exportar backup.

**Onde:** `lib/main.dart:16-19`

**Correção:** envolver a inicialização e, na falha, subir um app mínimo com o erro e duas ações —
tentar de novo e exportar os dados brutos.

### B-05 — A sincronia do widget deixa exceções escaparem

`syncHomeWidgetStatus()` protege só o `initialize()`; as chamadas a `HomeWidget.saveWidgetData` e
`updateWidget` ficam fora do `try`. Como a função é chamada com `unawaited` em três lugares,
qualquer falha vira erro assíncrono não tratado — no iOS, sem App Group configurado, isso lança de
fato.

**Onde:** `lib/services/widget_service.dart:47-61` · `lib/main.dart:22` ·
`lib/screens/dashboard_screen.dart:336`, `:362`

**Correção:** um `try/catch` cobrindo a função inteira. Atualizar o widget é acessório — nunca deve
derrubar nada.

---

## Lacunas de uso

Não são defeitos de código: são coisas que a pessoa precisa fazer e o app não deixa.

### L-01 — Não há como corrigir um dia passado *(alta)*

A edição foi restrita ao dia de calendário atual (commit `a194b8c`) e o histórico é somente leitura.
Quem esquecer de bater a saída ontem não tem nenhum caminho dentro do app: só exportando o backup,
editando o JSON na mão e reimportando. Num app de ponto, esquecer uma batida é o caso comum, não a
exceção — esta é a maior lacuna da lista.

**Onde:** `lib/screens/dashboard_screen.dart:199`, `:216` · `lib/screens/history_screen.dart`
(tiles sem ação)

**Proposta:** tocar num card do histórico abre um editor de dia — entrada, saída, observação e tipo
do dia — reaproveitando a validação de B-03. Se a intenção da restrição era evitar edição retroativa
descuidada, o meio-termo é permitir edição livre dentro do ciclo aberto e pedir confirmação para
ciclos já fechados.

### L-02 — O turno de sábado ficou sem editor *(média)*

O motor usa `WorkDayRule.saturdayCompensationShift` quando o dia é classificado como sábado de
compensação, mas depois da simplificação das configurações (commit `67f2f15`) nenhuma tela expõe
esse turno — o campo é só lido no `initState` e regravado igual. Na prática todo sábado trabalhado é
07:00–15:00, fixo, sem como mudar. E o app pede essa classificação toda vez que se bate ponto num
sábado.

**Onde:** `lib/screens/settings_screen.dart:68`, `:864` ·
`lib/domain/work_schedule/work_schedule_engine.dart:52`

**Proposta:** devolver o editor de turno de sábado à seção "Sábado e compensações", que hoje só tem
texto explicativo.

### L-03 — O almoço é uma constante, não uma batida *(média)*

Só existem duas batidas por dia e o intervalo é um `Duration` fixo descontado do bruto. Quem sai 40
minutos num dia e 1h30 no outro acumula erro de saldo todo dia, sem enxergar de onde vem.

**Onde:** `lib/models/time_record.dart:34-44` · `lib/domain/work_schedule/work_day_accounting.dart`

**Proposta:** intervalo opcional em quatro batidas, mantendo o desconto fixo como padrão de quem não
quiser registrar. Mexe no schema do Isar e no backup — planejar migração junto com D-01.

### L-04 — Nenhum lembrete *(produto)*

Não há notificação para bater entrada, para avisar que a saída prevista está chegando, nem para
alertar que o dia terminou sem saída registrada. É o recurso que mais reduziria a necessidade de
correção manual — e que torna L-01 menos frequente em vez de só mais fácil.

**Proposta:** notificações locais ancoradas no turno do dia, respeitando dias sem jornada prevista.

### L-05 — Faltam tipos de dia do mundo real *(produto)*

Férias, atestado, falta justificada e meio período não existem no modelo. Hoje esses dias caem em
"folga" (se houver regra manual) ou geram saldo negativo cheio, que o relatório em PDF leva adiante.

**Onde:** `lib/domain/work_schedule/work_schedule_models.dart:1-7`

**Proposta:** estender `WorkDayType` com esses casos e definir, para cada um, o esperado e como
aparece no relatório.

---

## Dívida técnica

Nada aqui quebra hoje. Tudo aqui torna as mudanças acima mais caras do que precisam ser.

### D-01 — Dois modelos concorrentes de "tipo de dia"

O `DayType` persistido no registro e o `WorkDayType` derivado das configurações convivem sem
contrato. O persistido nunca é escrito pelo app, o que deixa código morto em `TimeRecord.balance` e
em todo o `widget_service` — e foi exatamente essa ambiguidade que produziu B-02.

**Onde:** `lib/models/time_record.dart:8`, `:55-60` ·
`lib/domain/work_schedule/work_schedule_models.dart:1`

**Correção:** escolher uma fonte da verdade. O caminho natural é manter o derivado e ou remover o
campo persistido (com migração de backup), ou dar a ele um papel explícito de exceção por registro
que o motor consulte.

### D-02 — Configuração legada ainda viva e código sem uso

- **Configuração duplicada:** `dailyGoalMinutes` e `defaultEntry*/defaultExit*` foram substituídos
  pelo `WorkDayRule` e hoje aparecem na UI marcados como "compatibilidade", mas continuam
  persistidos e no backup.
- **Flag morta:** `saturdayCompensationEnabled` é salva, restaurada e nunca lida pelo motor.
- **Arquivo inteiro sem uso:** `lib/config/app_config.dart`, com o nome "Franklin" fixo no código.
- **Membros sem chamada:** `TimeRecordService.calculateTotalBalance`, `fillWithDefaultSchedule` e
  `TimeRecord.predictedExitTime`.

### D-03 — O cálculo de saldo depende de estado global

`TimeRecord.balance`, `totalWorkedHours` e `predictedExitTime` leem `AppSettingsService.current`
diretamente. O modelo passa a depender de um singleton estático: o resultado muda conforme o que
está carregado no processo, e no isolate do widget — que não inicializa as configurações — o cálculo
usa os padrões de fábrica.

**Correção:** mover para funções puras em `WorkDayAccounting` recebendo `AppSettings` como
parâmetro. O restante do domínio já segue esse padrão; é o modelo que destoa.

### D-04 — O saldo reconstrói o motor a cada leitura

Cada acesso a `record.balance` instancia um `WorkScheduleEngine`, remonta o mapa de feriados do ano
e varre `companyCalendarRules` linearmente. No histórico o saldo é lido cerca de três vezes por
registro a cada recomputação, e dashboard e insights carregam `getAllRecords()` inteiro para depois
filtrar em memória. Com um ano de dados isso é na casa dos milhares de alocações a cada toque num
filtro.

**Onde:** `lib/screens/history_screen.dart:160-192` ·
`lib/domain/work_schedule/work_schedule_engine.dart:103-123` ·
`lib/screens/dashboard_screen.dart:594`

**Correção:** três passos independentes — cachear feriados por ano e indexar as regras num `Map`
dentro do motor; calcular o saldo uma vez por registro e reusar; e trocar `getAllRecords()` por
consulta de intervalo no Isar (`dateBetween`), que o índice de `date` já suporta.

### D-05 — Formatadores duplicados em seis arquivos

`_formatDuration` e `_formatSignedDuration` estão reimplementados em seis lugares, e
`_sanitizeFileName` aparece idêntico — mesma tabela de acentos, mesmas regex — em `backup_service` e
`pdf_report_service`. Divergem no dia em que alguém mudar um só.

**Correção:** extrair para `lib/core/format/` e cobrir com teste, incluindo o caso de duração
negativa que hoje cada cópia trata sozinha.

### D-06 — O insight é filtrado depois de já ter sido cortado

`InsightsEngine.analyze` corta a lista em três itens e só então o painel descarta os de "padrão de
hora extra". Um insight descartado pode ter ocupado a vaga daquele que apareceria no lugar.

**Onde:** `lib/domain/insights/insights_engine.dart:72` ·
`lib/screens/widgets/dashboard_insights_panel.dart:12`

**Correção:** aplicar o filtro dentro do motor, antes do corte.

### D-07 — Testes cobrem o domínio; o resto não tem rede

Os 58 testes verdes cobrem quase só as classes puras. Ficam sem cobertura o `TimeRecordService` —
inclusive a lógica de turno aberto atravessando a meia-noite, que é a parte mais delicada do serviço
—, o ciclo real de exportar e importar backup pelo serviço, e as telas: `widget_test.dart` é um
smoke que monta um `Scaffold` com um texto, sem tocar no app. Também não há workflow em `.github/`,
embora `analyze` e `test` rodem limpos — CI aqui é barato.

**Correção:** workflow com `flutter analyze` e `flutter test` no push, e testes de serviço com Isar
em diretório temporário. Escrever primeiro os de B-03 e B-02, que fixam o comportamento correto
antes da correção.

### D-08 — Sobras de configuração e documentação defasada

- O código Kotlin está em `android/app/src/main/kotlin/com/seunome/auratime/` enquanto o `package`
  declarado é `com.auratime.app` — resto do template, funciona mas confunde.
- `isMinifyEnabled = false` e `isShrinkResources = false` no release: APK maior sem necessidade.
- O README anuncia "última versão v0.1.0-alpha" com o pubspec em 0.2.1+4, e o CHANGELOG parou na
  0.1.0 — a 0.2.x inteira não está registrada.
- `commit.bat` faz `git add .` e empurra direto para `main`; com CI no lugar, vale ao menos rodar os
  testes antes.

---

## Plano de execução

Cinco fases em ordem de dependência. As fases 1 e 2 são independentes entre si e podem ser feitas em
paralelo; da 3 em diante o trabalho fica mais barato se a 4 vier antes.

### Fase 1 — Destravar a publicação

Migrar para o fork `isar_community`, confirmar o alinhamento de 16 KB nos quatro ABIs, validar que
um banco existente abre sem perda e gerar um AAB de teste. Sem isso nada mais chega à loja.

`B-01` — risco: migração de banco, testar com dados reais antes.

### Fase 2 — Fechar os buracos de integridade

Guarda de calendário no widget (com as configurações carregadas no isolate), data-base correta na
edição de horário, inicialização protegida com tela de erro e `try/catch` completo na sincronia do
widget. Cada correção entra com o teste que a fixa.

`B-02` · `B-03` · `B-04` · `B-05`

### Fase 3 — Devolver o controle ao usuário

Edição de dias passados pelo histórico — reaproveitando a validação da fase 2 — e o editor de turno
de sábado de volta às configurações. É o que transforma o app de "registrador" em "ferramenta de
conferência".

`L-01` · `L-02`

### Fase 4 — Consolidar a base

Unificar o tipo de dia, tirar o cálculo de saldo do singleton, indexar o motor e usar consulta por
intervalo, extrair os formatadores, remover o legado e ligar o CI. Nada disso muda o comportamento —
tudo isso reduz o custo da fase 5.

`D-01` a `D-08`

### Fase 5 — Ampliar o produto

Registro de intervalo em quatro batidas, lembretes locais e os tipos de dia que faltam. Mexe em
schema e em backup, então depende da fase 4 estar fechada — em especial da unificação do tipo de
dia.

`L-03` · `L-04` · `L-05`

---

## Ordem sugerida

Tamanho relativo: **P** é uma sentada, **M** é um ou dois dias, **G** exige planejamento de migração.

| # | Item | Por quê agora | Tam. |
| --- | --- | --- | --- |
| B-01 | Migrar para `isar_community` | Único bloqueador de loja | G |
| B-03 | Data-base e validação na edição | Corrompe o saldo de quem corrige | P |
| B-02 | Guarda de calendário no widget | Grava ponto onde o app proíbe | M |
| B-04 | Boot protegido com tela de erro | Tira o usuário da tela branca | P |
| B-05 | `try/catch` na sincronia do widget | Erro assíncrono solto | P |
| D-07 | CI + testes de serviço | Rede para tudo que vem depois | M |
| L-01 | Editar dia no histórico | Maior lacuna de uso | M |
| L-02 | Editor de turno de sábado | Regra usada e não configurável | P |
| D-01 | Unificar o tipo de dia | Pré-requisito da fase 5 | M |
| D-04 | Indexar motor e consultar por intervalo | Cresce com o histórico | M |
| D-03 | Saldo como função pura | Destrava teste do cálculo | M |
| D-02 · D-05 · D-06 · D-08 | Limpezas e documentação | Baratas, reduzem ruído | P |
| L-04 | Lembretes locais | Reduz correção manual na origem | M |
| L-05 | Novos tipos de dia | Depende de D-01 | M |
| L-03 | Intervalo em quatro batidas | Migração de schema e backup | G |
