---
description: Fluxo completo - explora, planeja, implementa, testa e revisa
---
Tarefa: $ARGUMENTS

Siga este fluxo:
1. Use o agente Explore para achar os arquivos relevantes.
2. Use o agente Plan para propor um plano curto (maximo 8 passos).
3. Implemente o plano voce mesmo, em mudancas pequenas.
4. Use o agente tester para criar ou rodar os testes da mudanca.
5. Use o agente reviewer para revisar o git diff.
6. Corrija o que o reviewer apontar como grave.
Termine com um resumo de 5 linhas: o que mudou, resultado dos testes e veredito do reviewer.


Regras de git:
- Nunca trabalhe direto em main ou master; use uma branch.
- Um commit por passo logico, so com a verificacao passando.
- Mensagem no formato tipo: descricao (feat, fix, test, refactor, docs, chore), no imperativo, ate 72 caracteres.
- Antes de commitar rode git status e git diff --staged. Adicione arquivos pelo nome, nunca com git add -A ou git add .
- Nunca commite segredos (.env, chaves), node_modules, builds ou a pasta .auto.
- Nunca use push, --force, reset --hard, rebase, clean ou branch -D. Para desfazer algo seu, use git restore ou git revert.
- Rode git sempre sem -C e sem cd: o diretorio atual ja e o projeto (nunca use git -C).
