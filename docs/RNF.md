# Requisitos Nao Funcionais - RHOS (RH Operation System)
## Projeto Integrado 2026 | P.I-2026-RH-OS | Desenvolvido em Flutter/Dart

---

### RNF01 - Plataforma e compatibilidade
Aplicativo desenvolvido em Flutter 3.x e Dart 3.x, com foco atual em Android.
Compatibilidade com iOS e planejada para evolucao futura.

---

### RNF02 - Performance da triagem
O ranking de um lote de candidatos deve finalizar em ate 30s para 30 candidatos, com feedback visual de progresso e mensagens de erro claras.

---

### RNF03 - Disponibilidade da IA
Se a IA estiver indisponivel, o sistema deve executar fallback local sem interromper a operacao e registrar falhas tecnicas.

---

### RNF04 - Seguranca e autenticacao
O acesso deve ser protegido por Firebase Auth com perfis `admin` e `rh`, respeitando RBAC em rotas e operacoes.

---

### RNF05 - Persistencia e consistencia
Dados persistentes devem residir no Cloud Firestore. Operacoes criticas devem possuir tratamento de excecao e logs.

---

### RNF06 - Observabilidade
Erros de OCR/IA, ranking e persistencia devem ser reportados ao Crashlytics com contexto util (ex.: entidade, operacao e identificadores quando disponiveis).

---

### RNF07 - Usabilidade
Fluxos principais (cadastrar vaga, importar curriculo, ranquear) devem ser realizaveis em poucos passos e sem treinamento tecnico.

---

### RNF08 - Manutenibilidade
O projeto deve seguir separacao por camadas (core/data/domain/presentation), com DI via get_it e estado via Riverpod.

---

### RNF09 - Escalabilidade
A modelagem NoSQL deve suportar crescimento sem migracoes destrutivas e com indices adequados no Firestore.

---

### RNF10 - Privacidade
Dados sensiveis devem ser acessados apenas por perfis autorizados e nunca exibidos em logs de debug para usuario final.
