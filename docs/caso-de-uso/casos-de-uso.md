# Casos de Uso do Sistema

## UC00 — Autenticar no Sistema
**Ator Principal:** Recrutador, Administrador

**Objetivo:** Permitir que o usuário acesse o sistema com segurança.

**Pré-condições:**
- Usuário deve possuir cadastro ativo no sistema.

**Pós-condições:**
- Sessão iniciada e usuário redirecionado à tela inicial conforme seu perfil.

**Fluxo Principal:**
1. O usuário informa e-mail e senha.
2. O sistema valida as credenciais.
3. O sistema autentica o usuário e redireciona para a tela inicial.

**Fluxos Alternativos:**
- **A1 — Credenciais inválidas:**
  - O sistema exibe mensagem de erro e solicita nova tentativa.
- **A2 — Conta bloqueada:**
  - O sistema impede o acesso e instrui o usuário a contatar o administrador.

---

## UC01 — Importar e Cadastrar Currículo
**Ator Principal:** Recrutador

**Objetivo:** Permitir o envio e o cadastro de currículos de candidatos no sistema.

**Pré-condições:**
- Usuário autenticado (UC00).
- Arquivo no formato PDF ou imagem.

**Pós-condições:**
- Currículo armazenado e candidato cadastrado no banco de talentos.

**Fluxo Principal:**
1. O recrutador acessa a tela de importação de currículo.
2. O recrutador seleciona o arquivo (PDF ou imagem) no dispositivo.
3. O sistema valida o formato do arquivo.
4. O sistema envia o arquivo para processamento pela IA.
5. A IA extrai automaticamente as informações do currículo.
6. O sistema exibe os dados extraídos em campos editáveis para revisão.
7. O recrutador confirma ou corrige os dados.
8. O sistema salva o candidato no banco de talentos.

**Fluxos Alternativos:**
- **A1 — Formato não suportado:**
  - O sistema exibe mensagem de erro e solicita novo envio.
- **A2 — Falha na extração pela IA:**
  - O sistema notifica o recrutador e permite preenchimento manual dos campos.
- **A3 — Baixa qualidade de imagem:**
  - O sistema sinaliza os campos com baixa confiança de leitura para revisão manual.

---

## UC02 — Gerenciar Status do Candidato
**Ator Principal:** Recrutador

**Objetivo:** Permitir a atualização do status de um candidato ao longo do processo seletivo.

**Pré-condições:**
- Usuário autenticado (UC00).
- Candidato previamente cadastrado no sistema.

**Pós-condições:**
- Status do candidato atualizado e registrado no histórico do processo.

**Fluxo Principal:**
1. O recrutador acessa o perfil do candidato.
2. O recrutador seleciona o novo status (ex.: em análise, aprovado, reprovado).
3. O sistema registra a alteração com data e usuário responsável.
4. O sistema exibe confirmação da atualização.

**Fluxos Alternativos:**
- **A1 — Status inválido para a etapa atual:**
  - O sistema impede a transição e exibe uma mensagem explicativa.

---

## UC03 — Consultar Banco de Talentos
**Ator Principal:** Recrutador

**Objetivo:** Permitir a busca e filtragem de candidatos cadastrados no sistema.

**Pré-condições:**
- Usuário autenticado (UC00).
- Ao menos um candidato cadastrado no banco de talentos.

**Pós-condições:**
- Lista de candidatos filtrada exibida ao recrutador.

**Fluxo Principal:**
1. O recrutador acessa o banco de talentos.
2. O recrutador aplica filtros de busca (habilidade, formação, score mínimo, status).
3. O sistema retorna a lista de candidatos correspondentes, ordenada por score.
4. O recrutador seleciona um candidato para visualizar o perfil completo.

**Fluxos Alternativos:**
- **A1 — Nenhum resultado encontrado:**
  - O sistema exibe estado vazio e sugere ajuste nos filtros aplicados.

---

## UC04 — Cadastrar Vaga
**Ator Principal:** Recrutador

**Objetivo:** Permitir o cadastro de uma nova vaga com seus critérios de seleção.

**Pré-condições:**
- Usuário autenticado (UC00).

**Pós-condições:**
- Vaga criada e disponível para receber candidatos e iniciar processo seletivo.

**Fluxo Principal:**
1. O recrutador acessa a tela de cadastro de vagas.
2. O recrutador preenche as informações da vaga (cargo, área, requisitos, nível de experiência).
3. O recrutador define os critérios de classificação automática.
4. O sistema valida os dados informados.
5. O sistema salva a vaga e a disponibiliza para o processo seletivo.

**Fluxos Alternativos:**
- **A1 — Dados obrigatórios não preenchidos:**
  - O sistema impede o salvamento e destaca os campos pendentes.
- **A2 — Critério inválido ou conflitante:**
  - O sistema exibe erro de validação e solicita correção antes de prosseguir.

---

## UC05 — Classificar Candidatos por Critérios
**Ator Principal:** Recrutador

**Objetivo:** Classificar automaticamente os candidatos de uma vaga com base nos critérios definidos.

**Pré-condições:**
- Usuário autenticado (UC00).
- Vaga cadastrada com critérios definidos (UC04).
- Ao menos um candidato associado à vaga.

**Pós-condições:**
- Candidatos classificados e ordenados por score de compatibilidade.

**Fluxo Principal:**
1. O recrutador acessa a vaga e inicia a classificação.
2. O sistema recupera os critérios definidos para a vaga.
3. A IA calcula o score de compatibilidade de cada candidato.
4. O sistema exibe o ranking atualizado dos candidatos.

**Fluxos Alternativos:**
- **A1 — Critérios não configurados:**
  - O sistema bloqueia a classificação e redireciona o recrutador para o cadastro de critérios (UC04).
- **A2 — Candidato com dados insuficientes:**
  - O sistema atribui score parcial e sinaliza os campos ausentes no perfil.

---

## UC06 — Encerrar Processo Seletivo
**Ator Principal:** Recrutador, Administrador

**Objetivo:** Finalizar formalmente um processo seletivo, registrando o resultado.

**Pré-condições:**
- Usuário autenticado (UC00).
- Processo seletivo em andamento com ao menos um candidato avaliado.

**Pós-condições:**
- Processo encerrado, candidatos com status final registrado e vaga marcada como concluída.

**Fluxo Principal:**
1. O recrutador ou administrador acessa o processo seletivo da vaga.
2. O usuário seleciona a opção de encerramento.
3. O sistema solicita confirmação da ação.
4. O usuário confirma o encerramento.
5. O sistema registra o status final de cada candidato e encerra a vaga.

**Fluxos Alternativos:**
- **A1 — Processo sem candidato aprovado:**
  - O sistema exibe aviso e solicita confirmação explícita antes de encerrar.

---

## UC07 — Gerar Relatório do Processo
**Ator Principal:** Recrutador, Administrador

**Objetivo:** Gerar um relatório consolidado com os resultados do processo seletivo.

**Pré-condições:**
- Usuário autenticado (UC00).
- Processo seletivo encerrado (UC06).

**Pós-condições:**
- Relatório gerado e disponibilizado para download ou compartilhamento.

**Fluxo Principal:**
1. O usuário acessa a área de relatórios.
2. O usuário seleciona o processo seletivo desejado.
3. O sistema consolida os dados: candidatos avaliados, scores, status finais e critérios aplicados.
4. O sistema gera o relatório e disponibiliza para download.

**Fluxos Alternativos:**
- **A1 — Processo sem dados suficientes:**
  - O sistema informa que o processo não possui informações para gerar o relatório.

---

## UC08 — Gerenciar Usuários do Sistema
**Ator Principal:** Administrador

**Objetivo:** Permitir o cadastro, edição e desativação de usuários da plataforma.

**Pré-condições:**
- Administrador autenticado (UC00).

**Pós-condições:**
- Usuário criado, atualizado ou desativado conforme a ação realizada.

**Fluxo Principal:**
1. O administrador acessa o painel de gerenciamento de usuários.
2. O administrador seleciona a ação desejada (criar, editar ou desativar).
3. O administrador preenche ou atualiza os dados do usuário.
4. O sistema valida os dados e aplica a alteração.
5. O sistema exibe confirmação da operação realizada.

**Fluxos Alternativos:**
- **A1 — E-mail já cadastrado:**
  - O sistema impede o cadastro duplicado e informa o conflito.
- **A2 — Tentativa de desativar o próprio usuário:**
  - O sistema bloqueia a ação e exibe mensagem de restrição.

---

## Relação entre Casos de Uso e Funcionalidades do MVP

As funcionalidades definidas no MVP do projeto foram derivadas diretamente dos casos de uso identificados. A tabela abaixo documenta essa rastreabilidade.

| Funcionalidade do MVP | Casos de Uso Relacionados | Descrição da Relação |
|---|---|---|
| Autenticação de usuários | UC00 | Controle de acesso obrigatório para todas as demais funcionalidades. |
| Escanear currículos em PDF ou imagem | UC01 | O upload e a validação do arquivo são realizados integralmente neste caso de uso. |
| Extrair automaticamente informações do currículo | UC01 | A extração via IA ocorre como parte do fluxo de importação (passos 4 e 5 do UC01). |
| Gerar resumo automático do perfil profissional | UC01 | O resumo é gerado pela IA durante o processamento do currículo, ainda no fluxo do UC01. |
| Classificar candidatos por critérios da vaga | UC04, UC05 | UC04 define os critérios; UC05 executa a classificação automática com base neles. |
| Gerenciar status do candidato no processo | UC02 | Atualização manual do status ao longo das etapas do processo seletivo. |
| Consultar e filtrar candidatos cadastrados | UC03 | Busca no banco de talentos com filtros por habilidade, formação e score. |
| Encerrar processo seletivo | UC06 | Finalização formal do processo com registro do resultado de cada candidato. |
| Gerar relatório do processo seletivo | UC07 | Consolidação dos dados do processo encerrado para exportação e análise. |
| Gerenciar usuários da plataforma | UC08 | Exclusivo ao perfil Administrador; controle de acesso e permissões. |
