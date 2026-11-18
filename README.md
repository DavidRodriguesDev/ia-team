# ia-team

Time de agentes do OpenClaude, igual em todos os PCs, com um fluxo de TDD autônomo
que pode rodar isolado em Docker.

- [Requisitos](#requisitos)
- [Primeiros passos](#primeiros-passos)
- [Papéis e modelos](#papéis-e-modelos)
- [Comandos](#comandos)
- [Sandbox com Docker](#sandbox-com-docker)
- [Permissões](#permissões)
- [Atualizar e outros PCs](#atualizar-e-outros-pcs)
- [Outro time ou plano](#outro-time-ou-plano)
- [Problemas conhecidos](#problemas-conhecidos)
- [Limites conhecidos](#limites-conhecidos)

## Estrutura

    ia-team/
    ├── install.sh / install.ps1     instalam o time em ~/.openclaude
    ├── agents/                      reviewer, tester, spec-writer
    ├── commands/                    /feature /revisar /testar /autonomo /tdd
    ├── teams/ollama/settings.json   modelos, roteamento e permissões
    ├── sandbox/                     Dockerfile e entrypoint do container
    └── bin/ia-sandbox               roda o OpenClaude no container (Linux/macOS)

## Requisitos

| Para quê | O quê |
|---|---|
| Sempre | OpenClaude (`@twigpine/openclaude`), git, Ollama com `ollama signin` feito |
| Instalador | `jq` (sincroniza o modelo padrão do perfil; sem ele só avisa) |
| Sandbox | Docker ou Docker Desktop **aberto e rodando** |
| `overnight` | `tmux` (recomendado) e PC na tomada |

Os exemplos usam zsh/bash. O sandbox (`bin/ia-sandbox`) é para Linux/macOS.

## Primeiros passos

1. Clone o repo e instale, **com o OpenClaude fechado**:

        git clone https://github.com/DavidRodriguesDev/ia-team.git ~/Projetos/ia-team
        cd ~/Projetos/ia-team
        bash install.sh ollama          # Windows: .\install.ps1 -Team ollama

   O instalador:
   - faz backup do `~/.openclaude/settings.json` (`.bak.<timestamp>`) e o **substitui**
     pelo do time (não faz merge);
   - instala `agents/` e `commands/` (symlinks no Linux/macOS, cópias no Windows);
   - alinha o modelo padrão do perfil ativo (`~/.openclaude.json` e
     `~/.openclaude/.openclaude-profile.json`) ao `"model"` do time, com backup;
   - avisa se o `ollama` não está no PATH.

   Rodar de novo é seguro (não muda nada se já estiver alinhado).

2. Abra o OpenClaude e confira:
   - o banner mostra o modelo `deepseek-v4.1-flash:cloud`;
   - `/agents` lista `reviewer`, `tester` e `spec-writer` (o `inherit` ao lado é normal);
   - digitar `/` lista `feature`, `revisar`, `testar`, `autonomo` e `tdd`.

3. Teste o roteamento: peça "use o agente Explore para listar os arquivos principais"
   e abra a página de uso do ollama.com. O `glm-5.3-flash` deve registrar chamada.
   Repita com o `Plan` (kimi).

## Papéis e modelos

| Papel | Modelo | Quando age |
|---|---|---|
| lead | kimi-k3.1-pro | `Plan`, `reviewer`, `verification` e `spec-writer` |
| dev | deepseek-v4.1-flash | sessão principal e `general-purpose` |
| aux | glm-5.3-flash | `Explore` e `tester` |

Os papéis são apelidos em `agentModels`; para trocar um modelo, mude uma linha e rode
`bash install.sh ollama`. As rotas são só de modelo (sem `base_url` nem `api_key`): usam
o Ollama local (`localhost:11434`). Não há segredo no repo.

Dica de custo: não chame o `Plan` para tarefa pequena (ele roda no kimi) e use `/clear`
entre tarefas, porque cada mensagem reenvia o histórico inteiro.

## Comandos

Digite dentro do OpenClaude, na pasta do projeto.

### `/feature <meta>`
Explora, planeja, implementa, testa e revisa, com você acompanhando.

    /feature adicionar filtro por área na listagem de vagas

### `/revisar [foco]`
O `reviewer` (kimi) lê o `git diff` atual e devolve até 15 itens, do mais grave ao menos
grave, com veredito `APROVADO`, `APROVADO COM AJUSTES` ou `REPROVADO`. Só lê, não edita.

    /revisar foco em segurança

### `/testar <o quê>`
O `tester` (glm) cria ou roda testes e devolve só o resumo de passou/falhou.

    /testar cobrir o motorMatch.js

### `/autonomo <meta>`
Trabalha sozinho até um critério verificável. Exige repo limpo, cria a branch `auto/...`,
registra o plano em `.auto/progresso.md` (ignorado pelo git), commita cada passo que passa
e para ao concluir ou ao travar (máx. 20 passos, 4+4 tentativas por erro).

    /autonomo criar utils/soma.js com função soma(a,b) e um teste, passando em npm test

### `/tdd <meta>`
Igual ao `/autonomo`, mas com os testes escritos antes e **travados**:

1. `Explore` acha o código e a convenção de testes; `Plan` lista os comportamentos.
2. `spec-writer` (kimi) escreve os testes, confirma que falham pelo motivo certo e
   commita com `spec:`. O `reviewer` revisa esse commit (até 2 rodadas).
3. A implementação roda contra os testes, sem poder alterá-los (commits `feat:`/`fix:`).
4. `reviewer` revisa o diff final e o agente entrega um resumo de 8 linhas.

        /tdd criar utils/soma.js com função soma(a,b) que lança TypeError para não números

A meta deve dizer **como verificar** (ex.: `npm test`, `npm --prefix backend test`), sem
`cd` nem `&&`. O projeto precisa ter um script `test` no `package.json` commitado antes,
porque o `spec-writer` não edita configuração.

**Regras de git dos comandos:** nunca trabalhar direto em main/master; um commit por passo;
mensagem `tipo: descrição` (spec, feat, fix, refactor, docs, chore, test); adicionar arquivos
pelo nome; sem `push`, `--force`, `reset --hard`, `rebase`, `clean`, `branch -D` ou `commit --amend`.

## Sandbox com Docker

Roda o OpenClaude num container que só enxerga um **clone** do projeto (sem remote, sem
hardlinks): sem o seu `$HOME`, sem credenciais, sem `.env`. Roda como o seu usuário, sem
capabilities, com 4 GB de RAM e 2 CPUs. O Ollama continua no host; o container só chama a
API dele em `host.docker.internal:11434`.

### Preparar (uma vez)

    ln -sf ~/Projetos/ia-team/bin/ia-sandbox ~/.local/bin/ia-sandbox
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
    ia-sandbox build        # baixa a imagem e instala o OpenClaude (alguns minutos)
    ia-sandbox check        # esperado: 200

O pacote instalado na imagem deve ser `@twigpine/openclaude` (o antigo `@gitlawb/openclaude`
foi descontinuado). Confira no `sandbox/Dockerfile`. Refaça o `build` ao mudar a pasta `sandbox/`.

### Rodar interativo

    cd ~/Projetos/meu-projeto
    git switch main                   # repo limpo, numa branch comum
    ia-sandbox run

Dentro do OpenClaude, use `/tdd <meta>`. Ao sair, o script imprime o comando do `pull`.

### Rodar sem ninguém (`overnight`)

    cd ~/Projetos/meu-projeto
    tmux new -s noite
    IA_MAX_HOURS=6 ia-sandbox overnight . "<meta com comando de verificação>"
    # Ctrl+b e depois d para sair do tmux; tmux attach -t noite para voltar

- Não há terminal: comando fora da lista de permissões é **negado** em vez de esperar resposta.
- `IA_MAX_HOURS` (padrão 8) é só um teto. O `/tdd` termina sozinho ao concluir ou travar,
  normalmente em bem menos tempo.
- O script usa `systemd-inhibit` para o PC não suspender e avisa se não conseguir.
- Acompanhar de fora: `git -C ~/.ia-sandbox/<clone> log --oneline`; o log fica em
  `~/.ia-sandbox/<clone>.log` e o plano do agente em `<clone>/.auto/progresso.md`.
- Antes de dormir, confira: Docker Desktop aberto, Ollama rodando e logado, folga no plano
  do Ollama (uma rodada longa pode bater no limite e falhar no meio).

### Trazer o trabalho (`pull`)

    git switch main                                   # saia da branch do trabalho
    ia-sandbox pull ~/.ia-sandbox/<clone>

O `pull` roda **no host**, fora do container, e confere o travamento dos testes:

| Saída | Significa |
|---|---|
| `APROVADO NO TRAVAMENTO` | nenhum commit posterior alterou testes de um commit `spec:`; a branch foi trazida |
| `VIOLAÇÃO: commit ... altera teste travado` | a implementação mexeu num teste; nada é trazido |
| `REPROVADO: nenhum commit 'spec:'` | o fluxo TDD não foi seguido (`IA_ALLOW_NO_SPEC=1` ignora) |
| `REPROVADO: ... branch própria` | o trabalho ficou em main/master |

Depois de aprovado, **não confie no agente**; confira você mesmo:

    git diff <base>..auto/<nome>      # o comando exato aparece no fim do pull
    git switch auto/<nome> && npm test
    git switch main && git merge --no-ff auto/<nome>

Limpeza: `rm -rf ~/.ia-sandbox/<clone>*` (apaga o clone, o `.base`, o `.proj` e o `.log`) e
`git branch -d auto/<nome>`.

### Variáveis de ambiente

| Variável | Padrão | Uso |
|---|---|---|
| `IA_MAX_HOURS` | 8 | teto de tempo do `overnight` |
| `IA_MODEL` | deepseek-v4.1-flash:cloud | modelo da sessão principal no container |
| `IA_TEAM` | ollama | time usado dentro do container |
| `IA_WORK_ROOT` | ~/.ia-sandbox | onde ficam os clones |
| `OLLAMA_URL` | http://host.docker.internal:11434/v1 | endpoint do Ollama visto do container |
| `IA_IMAGE` | ia-team-sandbox | nome da imagem |
| `IA_ALLOW_NO_SPEC` | 0 | aceita no `pull` trabalho sem commit `spec:` |

### O que o container não tem

Banco de dados, outros serviços e variáveis do seu ambiente (o `.env` não vai no clone).
Prefira metas de lógica pura, e evite migrations, autenticação e rotas que consultam banco.

## Permissões

`teams/ollama/settings.json` usa `defaultMode: acceptEdits`, uma lista `allow` de comandos
seguros (git de leitura e commit, `npm test/run/install/ci`, `npm --prefix`, `node`, `cargo`,
`ls`, `cat`, `grep`, `find`...) e uma lista `deny` (`git push`, `reset --hard`, `clean`,
`rebase`, `branch -D`, `commit --amend`, `git -C`, `rm -rf`, `sudo`, leitura de `.env`).

Para liberar mais um comando (e depois rodar `bash install.sh ollama`):

    jq '.permissions.allow += ["Bash(make test:*)"] | .permissions.allow |= unique' teams/ollama/settings.json > /tmp/s.json && mv /tmp/s.json teams/ollama/settings.json

Pontos de atenção:
- O OpenClaude avisa que `acceptEdits` **desliga o classificador de segurança** em provedores
  de terceiros. Use o modo autônomo só em código seu e commitado, de preferência no sandbox.
- A regra casa com o **início** do comando. Por isso `git -C` é bloqueado: `git -C x push`
  não casaria com `git push`. Os agentes são instruídos a rodar git sem `-C`.

## Atualizar e outros PCs

    cd ~/Projetos/ia-team && git pull
    bash install.sh ollama            # com o OpenClaude fechado

Como os agentes e comandos são symlinks, editar um arquivo do repo vale na hora no Linux.
No Windows (cópias), rode o instalador de novo.

## Outro time ou plano

1. Copie `teams/ollama` para `teams/<nome>` e edite os modelos.
2. Se o provedor for outro, adicione `base_url` e `api_key` em cada entrada de `agentModels`.
3. Com chave, salve como `settings.local.json` (já ignorado pelo git).
4. `bash install.sh <nome>`.

## Problemas conhecidos

- **Banner com o modelo errado.** Vem do perfil de provedor de cada PC, não do `settings.json`.
  O `install.sh` corrige sozinho (precisa do `jq` e do OpenClaude fechado). Escolher outro
  modelo em `/model` regrava o perfil: rode o instalador de novo.
- **Pede confirmação mesmo com o comando liberado.** "Command contains quoted characters in
  flag names" é uma trava do próprio OpenClaude: um comando por chamada, sem `&&` e sem
  `echo "---x---"`. Variações como `git -C dir status` também não casam com `git status`.
- **`ia-sandbox: command not found`.** `~/.local/bin` não está no PATH (veja "Preparar").
- **`ia-sandbox check` não dá 200.** O container não alcança o Ollama do host: confira se o
  Docker Desktop e o Ollama estão rodando.
- **Erro de permissão ao escrever em `/work`.** Problema de bind mount do Docker; mande a
  mensagem completa para investigar.
- **`pull` falha ao trazer a branch.** O repo original está na branch de mesmo nome; volte
  para main antes.
- **`/agents` mostra `inherit` ou `haiku`.** A lista não reflete o `agentRouting`; vale o
  teste de uso no ollama.com.
- **Colar texto de várias linhas no terminal falhou em silêncio** algumas vezes. Prefira
  arquivos.

## Limites conhecidos

- A rede do container é aberta (necessária para `npm install`).
- Um agente mal-intencionado poderia reescrever o histórico do clone antes do `pull`; o `deny`
  de `amend`/`rebase`/`reset --hard` cobre o erro comum, não a má-fé.
- O travamento protege os arquivos de teste, mas não prova que os testes são bons; leia os
  commits `spec:` e o `.auto/progresso.md`.
- Os modelos flash perdem o fio em tarefas grandes; prefira uma feature pequena por vez.
- O custo que o OpenClaude mostra para modelos do Ollama é estimado; acompanhe o consumo na
  página de uso do Ollama. Os 3 slots simultâneos são da conta, então dois PCs com a mesma
  conta dividem os 3.
- Validado até aqui com uma feature pequena de teste; ainda não com um projeto real.
