# ia-team

Time de agentes do OpenClaude, igual em todos os PCs, com um fluxo de TDD
autônomo que roda isolado em Docker.

## Estrutura

    ia-team/
    ├── install.sh / install.ps1     instalam o time em ~/.openclaude
    ├── agents/                      reviewer, tester, spec-writer
    ├── commands/                    /feature /revisar /testar /autonomo /tdd
    ├── teams/ollama/settings.json   modelos, roteamento e permissões
    ├── sandbox/                     Dockerfile e entrypoint do container
    └── bin/ia-sandbox               roda o OpenClaude no container (Linux/macOS)

## Papéis (time `ollama`)

| Papel | Modelo | Quando age |
|---|---|---|
| lead | kimi-k3.1-pro | `Plan`, `reviewer`, `verification` e `spec-writer` |
| dev | deepseek-v4.1-flash | sessão principal e `general-purpose` |
| aux | glm-5.3-flash | `Explore` e `tester` |

Os papéis são apelidos em `agentModels`; para trocar um modelo, mude uma linha.
As rotas são só de modelo (sem `base_url` nem `api_key`): usam o Ollama local
(`localhost:11434`, logado com `ollama signin`). Não há segredo no repo.

## Instalar em um PC

    bash install.sh ollama        # Linux/macOS
    .\install.ps1 -Team ollama    # Windows

O script faz backup do `~/.openclaude/settings.json` (`.bak.<timestamp>`),
**substitui** pelo do time (não faz merge) e instala agentes e comandos.
Linux/macOS: symlinks (se mover o repo, quebram). Windows: cópias (rode de novo
após editar). Rodar de novo é seguro.

## Comandos

| Comando | O que faz |
|---|---|
| `/feature <meta>` | explora, planeja, implementa, testa e revisa |
| `/revisar [foco]` | `reviewer` no `git diff` atual |
| `/testar <o quê>` | `tester` cria ou roda testes e resume |
| `/autonomo <meta>` | trabalha sozinho até um critério verificável, em branch própria |
| `/tdd <meta>` | igual ao autônomo, mas os testes são escritos antes e travados |

### O fluxo `/tdd`

1. `Explore` acha o código e a convenção de testes; `Plan` lista os comportamentos.
2. `spec-writer` (kimi) escreve os testes, confirma que falham pelo motivo certo
   e commita com `spec:`. O `reviewer` revisa esse commit.
3. A implementação roda contra os testes, sem poder alterá-los.
4. `reviewer` revisa o diff final.

O travamento é conferido **fora do container**, no `ia-sandbox pull`: se qualquer
commit posterior (ou mudança não commitada) alterar um arquivo de um commit `spec:`,
o trabalho é reprovado e nada é trazido.

## Sandbox (Docker)

O container só enxerga um **clone** do projeto (sem remote, sem hardlinks), sem o
seu `$HOME`, sem credenciais e sem `.env`. Roda como o seu usuário, sem
capabilities, com 4 GB e 2 CPUs. O Ollama continua no host.

    ia-sandbox build                          # uma vez (e ao mudar o sandbox/)
    ia-sandbox check                          # esperado: 200
    ia-sandbox run [projeto]                  # interativo
    ia-sandbox overnight <projeto> "<meta>"   # sem ninguém, com limite de tempo
    ia-sandbox pull <clone>                   # confere o travamento e traz a branch

Para usar o comando direto: `ln -sf ~/Projetos/ia-team/bin/ia-sandbox ~/.local/bin/ia-sandbox`
e ter `~/.local/bin` no PATH.

- O projeto precisa estar **sem mudanças não commitadas** e numa branch comum
  (main/master). Um script `test` no `package.json` deve estar commitado antes.
- `overnight` não tem terminal: comando fora da lista de permissões é negado em vez
  de esperar resposta. `IA_MAX_HOURS` (padrão 8) é só um teto; o `/tdd` termina
  sozinho ao concluir ou travar. Impede a suspensão do PC com `systemd-inhibit`.
- Antes do `pull`, saia da branch do trabalho no repo original (volte para main).
- A meta deve dizer como verificar, sem `cd` nem `&&` (ex.: `npm --prefix backend test`).
- O container não tem banco de dados nem serviços: prefira lógica pura.

## Permissões

`teams/ollama/settings.json` usa `defaultMode: acceptEdits`, uma lista `allow` de
comandos seguros e uma lista `deny` (`git push`, `reset --hard`, `rebase`, `clean`,
`branch -D`, `commit --amend`, `git -C`, `rm -rf`, `sudo`, leitura de `.env`).

O OpenClaude avisa que `acceptEdits` desliga o classificador de segurança em
provedores de terceiros. Use o modo autônomo só em código seu e commitado, e de
preferência dentro do sandbox. O `deny` casa com o **início** do comando, por isso
`git -C` é bloqueado: `git -C x push` não casaria com `git push`.

## Outro time / outro plano

1. Copie `teams/ollama` para `teams/<nome>` e edite os modelos.
2. Se o provedor for outro, adicione `base_url` e `api_key` em cada `agentModels`.
3. Com chave, salve como `settings.local.json` (ignorado pelo git).
4. `bash install.sh <nome>`.

## Conferir antes de usar

1. Tags dos modelos: `ollama run kimi-k3.1-pro:cloud`, `deepseek-v4.1-flash:cloud`,
   `glm-5.3-flash:cloud`. Se faltar, pegue a tag certa em ollama.com.
2. No OpenClaude, `/agents` deve listar `reviewer`, `tester`, `spec-writer`
   (o `inherit` ao lado é normal) e `/` deve listar os comandos.
3. `/model` deve mostrar o deepseek.
4. Rode uma tarefa com `Explore` e outra com `Plan` e confira em ollama.com (uso)
   se glm e kimi foram chamados.

## Problemas conhecidos

- **Modelo padrão errado (`ollama run gemma4:31b-cloud`).** Vem do perfil de provedor:
  `~/.openclaude.json` (`providerProfiles[].model`) e `~/.openclaude/.openclaude-profile.json`
  (`OPENAI_MODEL`). Devem ter só o nome do modelo. Edite com o OpenClaude fechado.
  O instalador avisa se achar `ollama run`.
- **`"model"` do settings mudou sozinho.** Escolher outro modelo em `/model` regrava
  o campo. Rode o `install.sh` de novo.
- **Pede confirmação mesmo com a regra liberada.** "Command contains quoted characters
  in flag names" é uma trava do próprio OpenClaude: use um comando por chamada, sem
  `&&` e sem `echo "---x---"`. Comandos como `git -C dir status` não casam com
  `git status` na lista de permissões.
- **Pacote `@gitlawb/openclaude` descontinuado.** O novo é `@twigpine/openclaude`
  (desinstale o antigo antes). O Dockerfile já usa o novo, com Node 26.
- **Shell.** Os exemplos são para zsh/bash. Textos multilinha colados no terminal já
  falharam em silêncio: prefira arquivos.

## Limites conhecidos

- A rede do container é aberta (necessária para `npm install`).
- Um agente mal-intencionado poderia reescrever o histórico do clone antes do `pull`;
  o `deny` de `amend`/`rebase`/`reset --hard` cobre o erro comum, não a má-fé.
- O custo que o OpenClaude mostra para modelos do Ollama é estimado; acompanhe o
  consumo na página de uso do Ollama. Os 3 slots simultâneos são da conta.
