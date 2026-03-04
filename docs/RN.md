# Regras de Negócio – RHOS (RH Operation System)
## Projeto Integrado 2026 | P.I-2026-RH-OS | Desenvolvido em Flutter/Dart

---

### RN01 – Unicidade de Candidato por CPF ou E-mail

Não é permitido cadastrar dois candidatos com o mesmo CPF ou o mesmo endereço de e-mail no sistema. Caso o recrutador tente importar ou cadastrar um currículo de alguém que já existe na base, o sistema deve identificar a duplicidade e perguntar se deseja atualizar o perfil existente ou cancelar a operação.

---

### RN02 – Participação em Processos Seletivos

Um mesmo candidato não pode participar do mesmo processo seletivo mais de uma vez. Se o sistema identificar que o candidato já está inscrito em determinado processo, deve bloquear nova inscrição e informar ao recrutador que ele já consta naquele processo.

---

### RN03 – Obrigatoriedade do Motivo de Reprovação

Ao marcar um candidato como reprovado em qualquer etapa do processo seletivo, o recrutador é obrigado a registrar um motivo. Esse campo não pode ser deixado em branco, pois a informação é essencial para o histórico e para eventuais consultas futuras em processos de repescagem.

---

### RN04 – Prazo para Inclusão no Banco de Talentos

Um candidato só pode ser adicionado ao banco de talentos durante o processo seletivo ativo ou em até 30 dias após o encerramento do processo. Fora desse prazo, o candidato ainda pode ser visualizado no histórico, mas não poderá ser movido para o banco de talentos retroativamente sem uma nova avaliação.

---

### RN05 – Validade do Currículo no Banco de Talentos

Currículos armazenados no banco de talentos têm validade de 12 meses a partir da data em que foram incluídos. Após esse período, o sistema deve sinalizar o currículo como desatualizado e notificar o recrutador para que tome uma decisão: revalidar o cadastro, entrar em contato com o candidato para atualização ou remover o perfil.

---

### RN06 – Classificação Baseada nos Critérios da Vaga

A classificação automática dos candidatos só pode ser realizada se ao menos um critério de seleção estiver cadastrado na vaga correspondente. Sem critérios definidos, o sistema não realiza o ranqueamento automático e exibe os candidatos em ordem de cadastro.

---

### RN07 – Alteração de Status com Registro em Log

Toda alteração de status de um candidato dentro de um processo seletivo deve ser registrada automaticamente no sistema com data, horário e identificação do usuário que realizou a alteração. Esse registro não pode ser editado ou excluído, servindo como trilha de auditoria do processo.

---

### RN08 – Permissões por Nível de Acesso

Usuários com perfil de recrutador não podem criar, editar ou excluir outros usuários do sistema. Também não podem excluir candidatos da base de dados, apenas arquivá-los. Somente o administrador tem permissão para realizar operações que impactam a estrutura de usuários e dados permanentes do sistema.

---

### RN09 – Encerramento de Processo Seletivo

Um processo seletivo só pode ser encerrado pelo administrador ou pelo recrutador responsável por ele. Ao encerrar, o sistema verifica se ainda há candidatos com status "Em análise" e, caso haja, exige que o recrutador defina um status final para todos antes de concluir o encerramento.

---

### RN10 – Geração de Relatório

Relatórios só podem ser gerados para processos seletivos que já foram encerrados ou que estejam em andamento há mais de 7 dias. Processos recém-criados ou com menos de uma semana de atividade não geram relatório, pois os dados ainda são considerados insuficientes para análise.
