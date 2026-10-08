# Mamata 🍊💰

Jogo 2D de corrida satírico feito em **Flutter + Flame**. Você é um político que corre pelo
mandato roubando pacotes de dinheiro, taxando cidadãos e fugindo da **Verdade**. Pegue
**laranjas** para passar ileso pelos escândalos (CPI, CPMI, TCU, Polícia Federal…) e chegue
à **Reeleição**.

> Obra de ficção e sátira. Nenhum personagem, partido ou fato real é retratado.

## O jogo

| Fase | Tema | Escândalos novos |
|---|---|---|
| Ano 1 — A Posse | manhã | CPI, Jornalista |
| Ano 2 — Primeiro Escândalo | tarde | Drone da Imprensa (abaixar), Auditoria do TCU (pulo duplo) |
| Ano 3 — A CPMI | pôr do sol | CPMI (larga), Polícia Federal (rápida) |
| Ano 4 — Rumo à Reeleição | noite | Delação Premiada (voadora), Mandado de Busca — chegada na **urna da Reeleição** |

- **A Verdade** persegue o político. Cada escândalo sofrido a aproxima; ela recua aos poucos
  enquanto você corre limpo. Se alcançar você, aparece a manchete no *Jornal da Verdade*.
- **Laranjas** (máx. 5) assumem a culpa de um escândalo cada.
- **Imposto**: arremesse boletos nos cidadãos (ou esbarre neles) para arrecadar.
- **Poderes**: Foro Privilegiado (imunidade), Fake News (empurra a Verdade), Emenda
  Parlamentar (ímã de dinheiro), Mala de Dinheiro (+R$ 500 mil).
- **3 estrelas** por fase: concluir · no máximo 1 escândalo · desviar ≥ 60% do dinheiro.

### Controles

| Ação | Toque | Teclado |
|---|---|---|
| Pular / pulo duplo | toque no lado direito | Espaço / ↑ / W |
| Abaixar | segure o lado esquerdo | ↓ / S |
| Cobrar imposto | botão **R$ IMPOSTO** | X / F / Enter |
| Pausar | botão ⏸ / voltar do Android | Esc / P |
<<<<<<< HEAD

## Estrutura

```
lib/
  main.dart                  app, ciclo de vida, botão voltar, overlays
  game/
    mamata_game.dart         regras, estados, geração de fases, colisões
    levels.dart              configuração das 4 fases (velocidade, obstáculos, cores)
    paint_utils.dart         helpers de desenho (toda a arte é vetorial/procedural)
    components/              político, Verdade, obstáculos, coletáveis, cidadãos, cenário…
  services/                  áudio (pool de efeitos + música) e progresso (shared_preferences)
  ui/                        menus, HUD, telas de fase/pausa/fim (widgets Flutter)
assets/  audio/ (gerado)  fonts/ (Lilita One, OFL)  icon/ (gerado)
tool/
  gen_audio.py               sintetiza efeitos e músicas  →  assets/audio
  gen_icon.py                gera ícone e arte de destaque (Pillow)
  preview_main.dart          entrada de depuração para capturas de tela
store/                       ícone 512, feature graphic, screenshots e textos da Play Store
test/game_test.dart          testes: Verdade alcança, laranjas, impostos, as 4 fases concluíveis
```

## Rodando

```bash
flutter pub get
flutter run                 # celular/emulador Android (paisagem)
flutter run -d chrome       # navegador
flutter test                # testes automatizados
```

Para regerar assets: `python tool/gen_audio.py`, `python tool/gen_icon.py` e
`dart run flutter_launcher_icons`.

## Publicando na Google Play

1. **ID do app** — em [android/app/build.gradle.kts](android/app/build.gradle.kts) troque
   `applicationId = "br.com.mamata.game"` pelo seu (ex.: `com.seuestudio.mamata`).
   Depois da primeira publicação ele não pode mudar.
2. **Chave de upload** (uma única vez, guarde em local seguro):
   ```bash
   keytool -genkey -v -keystore %USERPROFILE%\mamata-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   Copie [android/key.properties.example](android/key.properties.example) para
   `android/key.properties` e preencha (o arquivo está no `.gitignore`).
3. **Versão** — em `pubspec.yaml`, `version: 1.0.0+1` (o número após o `+` é o
   `versionCode` e deve aumentar a cada envio).
4. **Gerar o bundle**:
   ```bash
   flutter build appbundle --release
   ```
   Saída: `build/app/outputs/bundle/release/app-release.aab`.
5. **Play Console** — crie o app, envie o `.aab` (teste interno → produção) e preencha:
   - Ficha da loja: textos em [store/listing.md](store/listing.md), ícone
     `store/icon_512.png`, arte `store/feature_graphic.png`, capturas `store/screenshots/`.
   - Política de privacidade: publique [PRIVACY_POLICY.md](PRIVACY_POLICY.md) em uma URL
     pública (GitHub Pages, Google Sites…) e informe a URL.
   - Segurança dos dados: **nenhum dado coletado ou compartilhado**.
   - Classificação de conteúdo (IARC): jogo, humor/sátira, sem violência realista, sem
     compras, sem anúncios, sem interação entre usuários.
   - Público-alvo: 13+ (sátira política).

Configuração Android já pronta: `targetSdk 36`, orientação paisagem, ícone adaptativo,
splash na cor do jogo, R8/shrink no release, `appCategory="game"`, sem permissões.
=======
>>>>>>> 34ac65cb2275d96b8d365cc4a7273c1ba62ce815
