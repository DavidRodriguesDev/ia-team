---
description: TDD autonomo - testes definidos antes e travados, depois a implementacao
---
Objetivo: $ARGUMENTS

Trabalhe de forma autonoma. NAO faca perguntas ao usuario: em caso de duvida, escolha a opcao mais simples e registre a decisao em .auto/progresso.md.

Este fluxo tem DUAS fases. Os testes sao escritos e travados ANTES da implementacao. Depois do commit "spec:", ninguem altera esses testes. O ambiente confere isso fora do container; qualquer alteracao invalida o trabalho.

Preparacao:
1. Rode git status. Se houver mudancas nao commitadas, pare e avise.
2. Crie a branch auto/<resumo-curto> a partir da atual.
3. Crie .auto/progresso.md com o objetivo e o plano.

Fase 1 - Especificacao:
1. Use o agente Explore para achar os arquivos relevantes e a convencao de testes do projeto.
2. Use o agente Plan para propor um plano curto e a lista de comportamentos que os testes devem cobrir. Sem codigo.
3. Use o agente spec-writer, passando o objetivo e o plano do Plan. Ele escreve os testes, confirma que falham pelo motivo certo e faz o commit "spec: ...".
4. Use o agente reviewer para revisar SOMENTE o commit spec: cobertura do objetivo, asserções fracas, testes triviais. Se houver problema grave, chame o spec-writer de novo para corrigir em um novo commit "spec: ...". No maximo 2 rodadas.

Fase 2 - Implementacao (testes travados):
- NUNCA edite, apague, renomeie, desative (skip, only, xit) nem enfraqueca arquivos de teste commitados em "spec:". Nao crie atalhos que reconhecam os testes.
- Se achar que um teste esta errado, PARE. Escreva em .auto/progresso.md qual teste, por que e o que sugere, e termine relatando. Nao contorne.
- Loop: pegue um passo pequeno, implemente, rode os testes, commite com "feat:" ou "fix:" quando avancar. Se o mesmo erro persistir por 4 tentativas, mude de abordagem; por mais 4, PARE e relate o bloqueio. Maximo de 20 passos.
- Termine quando a suite inteira do projeto passar.

Fase 3 - Fechamento:
1. Rode a suite completa uma ultima vez.
2. Use o agente reviewer no git diff da branch inteira e corrija o que for grave (sem tocar nos testes travados).
3. Termine com resumo de 8 linhas: o que foi feito, comando para verificar, decisoes, testes que voce achou duvidosos e pendencias.

Regras de git:
- Nunca trabalhe direto em main ou master.
- Mensagem no formato tipo: descricao (spec, feat, fix, refactor, docs, chore), no imperativo, ate 72 caracteres.
- Antes de commitar rode git status e git diff --staged. Adicione arquivos pelo nome, nunca com git add -A ou git add .
- Nunca commite segredos, node_modules, builds ou a pasta .auto.
- Nunca use push, --force, reset --hard, rebase, clean, branch -D nem commit --amend.
- Use um comando simples por chamada de Bash: nunca encadeie com && ou ;.
- Rode git sempre sem -C e sem cd: o diretorio atual ja e o projeto (nunca use git -C).
