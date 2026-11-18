---
description: Trabalha sozinho ate cumprir um objetivo verificavel
---
Objetivo: $ARGUMENTS

Trabalhe de forma autonoma. NAO faca perguntas ao usuario: em caso de duvida, escolha a opcao mais simples e registre a decisao.

Preparacao:
1. Rode git status. Se houver mudancas nao commitadas, pare e avise.
2. Crie a branch auto/<resumo-curto> a partir da atual.
3. Defina um CRITERIO DE PRONTO verificavel por comando (testes passando, build ok, script rodando). Se o objetivo nao tiver um, crie o teste que o represente primeiro.
4. Crie .auto/progresso.md com: objetivo, criterio de pronto, plano e uma lista de passos.

Loop (repita ate o criterio passar):
1. Pegue o proximo passo pequeno do plano.
2. Implemente.
3. Rode o criterio de verificacao.
4. Se passou, faca git commit com mensagem clara e marque o passo em .auto/progresso.md.
5. Se falhou, corrija. Se o mesmo erro persistir por 4 tentativas, mude de abordagem. Se persistir por mais 4, PARE e relate o bloqueio.

Limites:
- Use um comando simples por chamada de Bash: nunca encadeie com && ou ;, e nunca use echo com textos entre aspas que comecem com tracos.
- No maximo 20 passos no total. Ao chegar nele, pare e relate o que falta.
- Nunca use git push, nem apague fora do projeto, nem mexa em .env ou ~/.openclaude.
- Nao instale dependencias globais.
- Releia .auto/progresso.md quando perder o contexto.

Ao cumprir o criterio:
1. Use o agente tester para conferir a cobertura dos testes.
2. Use o agente reviewer no git diff da branch e corrija o que for grave.
3. Termine com resumo de 8 linhas: o que foi feito, como verificar, decisoes tomadas e pendencias.


Regras de git:
- Nunca trabalhe direto em main ou master; use uma branch.
- Um commit por passo logico, so com a verificacao passando.
- Mensagem no formato tipo: descricao (feat, fix, test, refactor, docs, chore), no imperativo, ate 72 caracteres.
- Antes de commitar rode git status e git diff --staged. Adicione arquivos pelo nome, nunca com git add -A ou git add .
- Nunca commite segredos (.env, chaves), node_modules, builds ou a pasta .auto.
- Nunca use push, --force, reset --hard, rebase, clean ou branch -D. Para desfazer algo seu, use git restore ou git revert.
- Rode git sempre sem -C e sem cd: o diretorio atual ja e o projeto (nunca use git -C).
