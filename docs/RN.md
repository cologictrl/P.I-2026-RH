# Regras de Negocio - RHOS (RH Operation System)
## Projeto Integrado 2026 | P.I-2026-RH-OS | Desenvolvido em Flutter/Dart

---

### RN01 - Unicidade de candidato por CPF ou e-mail
Nao e permitido cadastrar dois candidatos com o mesmo CPF ou o mesmo e-mail.
Ao detectar duplicidade no cadastro/importacao de curriculo, o sistema deve permitir atualizar o perfil existente ou cancelar a operacao.

---

### RN02 - Vinculo unico por vaga
Um candidato nao pode ter mais de uma candidatura para a mesma vaga.

---

### RN03 - Qualidade minima do perfil
Para salvar candidato com perfil completo, o resumo deve estar preenchido e deve existir ao menos uma habilidade.

---

### RN04 - Ranking exige dados minimos da vaga
Para executar ranqueamento, a vaga deve ter ao menos requisitos textuais ou habilidades cadastradas.
Se nao houver criterios, o sistema nao executa ranking automatico.

---

### RN05 - Rubrica padronizada
Cada eixo da rubrica deve usar escala 0..5 e o score total deve ficar entre 0..100, com pesos configuraveis.

---

### RN06 - Status com auditoria
Toda mudanca de status de candidatura deve registrar auditoria com data/hora e usuario responsavel.

---

### RN07 - Permissoes por perfil
Apenas perfil `admin` pode gerir usuarios e configuracoes administrativas.
Perfil `rh` pode operar vagas, candidaturas, ranking e entrevistas.

---

### RN08 - Entrevista apos aprovacao
Ao aprovar candidato, o sistema deve oferecer agendamento de entrevista e gerar notificacao.

---

### RN09 - Exclusao de candidatura remove ranking associado
Ao excluir candidatura, o ranking associado deve ser removido para evitar dados inconsistentes.
