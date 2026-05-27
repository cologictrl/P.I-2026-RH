# Documento de Arquitetura de Software - RHOS (RH Operation System)

Projeto Integrado 2026 | P.I-2026-RH-OS | Flutter/Dart

## 1. Visao de arquitetura

O RH-OS segue separacao em camadas com responsabilidades claras:

- `presentation`: telas, widgets, navegacao e interacao com usuario.
- `domain`: entidades, casos de uso e contratos de repositorio.
- `data`: implementacoes concretas para Firebase/Firestore, parsers e servicos.
- `core`: tema, constantes, utilitarios e injecao de dependencias.

A regra de dependencia e: `presentation -> domain <- data`.

## 2. Tecnologias e papeis

- Flutter: UI mobile.
- Riverpod: estado reativo de telas/fluxos.
- GoRouter: navegacao declarativa.
- get_it: injecao de dependencia.
- Firebase Auth: autenticacao por e-mail/senha.
- Cloud Firestore: persistencia principal.
- Gemini API: apoio de IA para OCR/ranking (com fallback local).
- Crashlytics: observabilidade de erros tecnicos.

## 3. Fluxo de autenticacao e controle de acesso

- Login e feito via Firebase Auth.
- Sessao local usa `usuario_uid` e `usuario_perfil`.
- Perfis de negocio: `admin` e `rh`.
- O controle de acesso por tela existe na UI e menus; RBAC por rota no GoRouter ainda e uma melhoria recomendada.

## 4. Persistencia e colecoes

Colecoes principais no Firestore:

- `usuarios`
- `candidatos`
- `vagas`
- `candidaturas`
- `rankings`
- `entrevistas`
- `notificacoes`

## 5. OCR e ranking

### 5.1 Upload e extracao

1. Usuario seleciona PDF/imagem.
2. Parser tenta extracao textual direta.
3. Sem texto util, usa OCR com Gemini.
4. Em falha/indisponibilidade, aplica fallback local.
5. Dados extraidos sao mapeados para entidade de candidato.

### 5.2 Ranqueamento

- Ranking com rubrica 0..5 por eixo.
- Score total normalizado 0..100 com pesos configuraveis.
- Resultado pode incluir gating e requisitos nao atendidos.
- Persistencia de ranking ocorre no Firestore para reuso/recalculo.

## 6. Qualidade e manutencao

- Testes automatizados em `test/` cobrem entidades, validadores, parser e ranking.
- Tratamento de erro com `try/catch` e `recordError` no Crashlytics nas rotas criticas.
- Documentacao funcional e tecnica centralizada em `docs/`.

## 7. Aderencia documentacao x codigo (estado atual)

Conforme:

- Arquitetura em camadas e DI.
- Integracao Firebase Auth/Firestore.
- Fluxo OCR + fallback local.
- Ranking com score normalizado e cache.

Pontos de alinhamento continuo:

- Consolidar RBAC por rota no GoRouter.
- Padronizar totalmente a nomenclatura de perfil (`rh` x `recrutador`) em todos os artefatos legados.
- Manter diagramas sincronizados quando contratos de interfaces mudarem.
