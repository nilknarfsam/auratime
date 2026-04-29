# AuraTime

AuraTime e um aplicativo Flutter para controle de jornada com foco em visual premium, rapidez no registro e acompanhamento de saldo de horas.

## Funcionalidades atuais

- Dashboard com registro de ponto de entrada/saida.
- Status do dia, progresso da jornada e previsao de saida.
- Resumo semanal direto no dashboard.
- Historico com filtros por periodo e resumo consolidado.
- Exportacao de relatorio em PDF.
- Configuracoes de usuario e jornada (nome, horarios, almoco e meta diaria).
- Persistencia local com Isar e SharedPreferences.
- Widget Android para atalho de batida de ponto.

## Prints (em breve)

- [ ] Dashboard premium
- [ ] Historico com filtros
- [ ] Configuracoes
- [ ] Relatorio PDF

## Como rodar

1. Instale o Flutter SDK e valide com:
   - `flutter doctor`
2. Instale dependencias:
   - `flutter pub get`
3. Execute no dispositivo/emulador:
   - `flutter run`

## Como gerar APK

- Build debug:
  - `flutter build apk --debug`
- Build release:
  - `flutter build apk --release`

O APK gerado fica em `build/app/outputs/flutter-apk/`.
