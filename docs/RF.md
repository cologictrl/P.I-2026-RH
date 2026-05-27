# Requisitos Funcionais - RHOS (RH Operation System)
## Projeto Integrado 2026 | P.I-2026-RH-OS | Desenvolvido em Flutter/Dart

---

### RF01 - Cadastro de candidatos
O sistema deve permitir cadastrar candidatos manualmente ou via leitura de curriculo (PDF/imagem), armazenando dados pessoais, formacao, experiencias, habilidades, idiomas e resumo.

---

### RF02 - OCR e extracao automatica
O aplicativo deve extrair automaticamente dados do curriculo com IA (Gemini) e aplicar fallback local quando a IA nao estiver disponivel.

---

### RF03 - Gestao de vagas
O recrutador deve cadastrar e editar vagas com titulo, descricao, requisitos, habilidades, soft skills, senioridade, local e modalidade.

---

### RF04 - Vinculo candidato-vaga
O sistema deve permitir vincular candidatos a vagas, criando uma candidatura com status inicial e data de candidatura.

---

### RF05 - Ranking por rubrica
O sistema deve calcular ranking por rubrica (0..5 por eixo) com score total normalizado 0..100, exibindo justificativa e pontos fortes/fracos.

---

### RF06 - Cache e recalculo de ranking
O ranking deve ser salvo no Firestore, permitindo reutilizacao do cache e opcao de refazer ranking por candidato ou por vaga.

---

### RF07 - Status de candidatura
O recrutador deve alterar o status da candidatura (em analise, aprovado, reprovado), com registro de auditoria.

---

### RF08 - Agendamento de entrevista
Ao aprovar um candidato, o sistema deve sugerir agendamento de entrevista e gerar notificacao ao candidato.

---

### RF09 - Controle de acesso
O sistema deve exigir autenticacao e manter dois perfis: administrador (`admin`) e recrutador (`rh`), com permissoes distintas.

---

### RF10 - Exclusao de candidatura
O recrutador deve poder remover uma candidatura e seus dados de ranking associados.

---

### RF11 - Notificacoes internas
O sistema deve gerar notificacoes internas para eventos importantes (ex.: entrevista agendada).

---

### RF12 - Relatorios
O sistema deve permitir gerar relatorios de processos seletivos com exportacao (fase futura).
