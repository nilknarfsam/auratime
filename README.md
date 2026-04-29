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

## Persistencia e atualizacoes

- Os dados do AuraTime ficam salvos localmente no Isar e nas preferencias do app.
- Atualizar o app por cima (upgrade de versao) nao deve apagar os dados existentes.
- Os dados podem ser perdidos se o usuario desinstalar o app, limpar os dados do aplicativo ou ocorrer uma falha grave de armazenamento.
- Para maior seguranca, use **Exportar backup** antes de instalar novas versoes.
- Nao altere nem remova campos do modelo `TimeRecord` sem uma estrategia de migracao e compatibilidade de backup.

## Downloads

- Ultima versao: **v0.1.0-alpha**
- APK debug de teste: `build/app/outputs/flutter-apk/app-debug.apk`
- Changelog: [CHANGELOG.md](./CHANGELOG.md)

> Em breve: link publico de download no GitHub Releases.
