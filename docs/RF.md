# Requisitos Funcionais – RHOS (RH Operation System)
## Projeto Integrado 2026 | P.I-2026-RH-OS | Desenvolvido em Flutter/Dart

---

### RF01 – Cadastro de Candidatos

O sistema deve permitir que o recrutador cadastre candidatos manualmente ou de forma automática a partir da leitura de um currículo em PDF ou imagem. No cadastro, devem ser armazenados dados como nome completo, contato, formação acadêmica, experiências profissionais, habilidades e o cargo ao qual o candidato está se aplicando.

---

### RF02 – Leitura e Extração Automática de Currículos

O aplicativo deve ser capaz de receber um arquivo de currículo nos formatos PDF ou imagem (JPG, PNG) e, utilizando inteligência artificial, extrair automaticamente as informações relevantes do documento, preenchendo os campos do cadastro do candidato sem necessidade de digitação manual por parte do recrutador.

---

### RF03 – Geração de Resumo do Perfil Profissional

Após a extração dos dados, o sistema deve gerar automaticamente um resumo do perfil do candidato, destacando os pontos mais relevantes com base nas informações encontradas no currículo, como tempo de experiência, principais habilidades e nível de formação.

---

### RF04 – Classificação de Candidatos por Critérios

O recrutador deve poder definir critérios de seleção para uma vaga, como formação mínima, palavras-chave de habilidades ou anos de experiência. Com base nesses critérios, o sistema deve classificar automaticamente os candidatos por nível de aderência à vaga, apresentando os mais compatíveis no topo da lista.

---

### RF05 – Controle de Status do Processo Seletivo

Cada candidato deve ter um status vinculado ao processo seletivo em que participou. Os status possíveis são: Em análise, Aprovado, Reprovado e Em banco de talentos. O sistema deve permitir que o recrutador altere esse status conforme o andamento do processo.

---

### RF06 – Registro de Histórico do Candidato

O sistema deve manter um histórico de cada candidato, registrando todos os processos seletivos dos quais ele participou, incluindo a data de participação, o cargo disputado e o motivo pelo qual não foi aprovado, quando for o caso. Esse histórico deve estar acessível ao recrutador sempre que o candidato for consultado novamente.

---

### RF07 – Banco de Talentos (Repescagem)

Candidatos que não foram aprovados em processos anteriores, mas que apresentaram bom desempenho, devem poder ser adicionados ao banco de talentos. O sistema deve permitir que o recrutador consulte esse banco a qualquer momento, filtrando por habilidades, cargo ou data de participação, facilitando a repescagem em novas oportunidades.

---

### RF08 – Autenticação e Controle de Acesso

O sistema deve exigir login com usuário e senha para acesso. Devem existir ao menos dois níveis de permissão: administrador, que pode cadastrar usuários e acessar todas as funcionalidades, e recrutador, que pode gerenciar candidatos e processos seletivos, mas não tem acesso às configurações do sistema.

---

### RF09 – Cadastro e Gerenciamento de Vagas

O sistema deve permitir que o recrutador cadastre vagas com informações como título do cargo, descrição das atividades, requisitos obrigatórios, requisitos desejáveis e prazo de inscrição. Cada vaga poderá ser vinculada a um ou mais processos seletivos.

---

### RF10 – Notificações e Alertas Internos

O sistema deve gerar alertas internos para o recrutador quando houver novos currículos pendentes de análise, quando um prazo de vaga estiver próximo do vencimento ou quando um candidato do banco de talentos tiver perfil compatível com uma nova vaga aberta.

---

### RF11 – Relatórios de Processo Seletivo

O sistema deve permitir a geração de relatórios dos processos seletivos, contendo informações como número de candidatos inscritos, quantidade aprovados e reprovados, tempo médio de triagem e os candidatos adicionados ao banco de talentos. Esses relatórios devem poder ser exportados em PDF.
