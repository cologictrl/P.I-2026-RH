# Documento de Visao do Produto RH-OS

## 1. Visao geral

RH-OS e um aplicativo mobile em Flutter para equipes de RH realizarem triagem, ranking e acompanhamento de candidatos com apoio de IA e regras de negocio claras.

## 2. Problema

Triagens manuais geram atraso, inconsistencias e baixa previsibilidade:

- Alto tempo de analise por vaga
- Avaliacao subjetiva entre recrutadores
- Dificuldade de rastrear historico e status

## 3. Proposta de solucao

O aplicativo permite:

- Upload de curriculos (PDF/imagem)
- OCR com Gemini e fallback local
- Cadastro de candidatos e vagas
- Ranking por rubrica (0..5 por eixo) com pesos configuraveis
- Cache de ranking no Firestore, com invalidacao e recalculo
- Gestao de candidaturas (status, aprovacao, reprova)
- Agendamento de entrevistas e notificacoes

## 4. Personas e beneficiados

- Recrutador: cria vagas, vincula candidatos, calcula ranking, acompanha status
- Administrador: gerencia usuarios e auditoria

## 5. Objetivos

### Objetivo geral
Automatizar e padronizar a triagem de curriculos com IA e regras auditaveis.

### Objetivos especificos
- Reduzir tempo de triagem
- Aumentar consistencia do ranking
- Melhorar rastreabilidade do processo
- Facilitar reavaliacao e repescagem

## 6. Metricas de sucesso

- Tempo medio de triagem por vaga
- Percentual de candidatos avaliados com rubrica completa
- Taxa de falha do ranking por indisponibilidade de IA
- Tempo medio entre aprovacao e agendamento de entrevista

## 7. ODS relacionado

ODS 8 - Trabalho Decente e Crescimento Economico
