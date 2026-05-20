# Requisitos Não Funcionais – RHOS (RH Operation System)
## Projeto Integrado 2026 | P.I-2026-RH-OS | Desenvolvido em Flutter/Dart

---

### RNF01 – Plataforma e Compatibilidade

O aplicativo é desenvolvido em Flutter com a linguagem Dart, garantindo compatibilidade nativa com dispositivos Android e iOS. O ambiente mínimo exigido para compilação é o Flutter SDK 3.0 ou superior. Para dispositivos Android, a versão mínima suportada é o Android 8.0 (API 26), e para iOS, a versão mínima é o iOS 13.

---

### RNF02 – Desempenho na Extração de Currículos

A leitura, processamento OCR e extração automática de informações de um currículo via inteligência artificial (Gemini API) deve ser concluída em no máximo 15 segundos para arquivos de até 5MB. Para arquivos maiores ou com múltiplas páginas, o sistema deve exibir obrigatoriamente uma barra de progresso visual para o usuário.

---

### RNF03 – Segurança e Autenticação

O aplicativo deve utilizar o sistema de autenticação nativo do **Firebase Authentication** com controle de permissões baseado em funções (RBAC) restrito a dois perfis (`admin` e `recrutador`). O gerenciamento e a expiração segura dos tokens de sessão de usuário ficam sob a responsabilidade das políticas e segurança nativas do SDK do Firebase Auth.

---

### RNF04 – Armazenamento de Dados

Todos os dados persistentes do aplicativo, incluindo registros de candidatos, vagas, logs e históricos, devem ser armazenados de forma centralizada e exclusiva no **Cloud Firestore**. A modelagem deve seguir as diretrizes NoSQL do ecossistema Firebase, abolindo o uso de bancos de dados locais estruturados relacionais complexos ou APIs REST externas de terceiros para a persistência básica.

---

### RNF05 – Usabilidade

A interface do sistema deve ser intuitiva e limpa, permitindo que um recrutador realize operações essenciais (como cadastrar uma vaga, importar um currículo e filtrar candidatos por score de compatibilidade) sem a necessidade de treinamento técnico prévio. O tempo estimado de aprendizado para uso básico do sistema não deve ultrapassar uma hora.

---

### RNF06 – Disponibilidade e Modo Offline

O aplicativo deve suportar o mecanismo de persistência e cache offline nativo fornecido pelo **SDK do Cloud Firestore** (*Firestore Offline Persistence*). Isso garantirá que os recrutadores visualizem e realizem consultas básicas em candidatos e vagas previamente carregados mesmo em ambientes sem conectividade com a internet. Operações que exijam inteligência artificial (Fase 2) e autenticação inicial exigem conexão ativa.

---

### RNF07 – Manutenibilidade

O código-fonte do projeto deve seguir rigorosamente os padrões de Arquitetura Limpa (Clean Architecture), segregando as responsabilidades de forma clara entre as camadas de Apresentação, Domínio e Dados. O uso de comentários e documentação nos métodos e widgets principais deve seguir o padrão oficial `dartdoc`.

---

### RNF08 – Escalabilidade

A estrutura de injeção de dependência via `get_it` combinada ao gerenciamento de estado isolado por recursos do `riverpod` deve permitir que novas coleções e fluxos de telas sejam adicionados sem impactar as regras de negócio existentes ou exigir refatorações estruturais em larga escala.

---

### RNF09 – Logs e Auditoria

Todas as alterações críticas efetuadas pelos usuários (como criação de vagas, exclusão/arquivamento de registros, logins e alterações de status de processos seletivos) devem disparar a gravação automática de um documento na coleção de `logs` no Firestore. Essa coleção deve ser protegida por regras do Firebase de modo a ser acessível unicamente por usuários com perfil `admin`.

---

### RNF10 – Tamanho e Formato de Arquivos Aceitos

O sistema de triagem deve aceitar arquivos de currículo estritamente nos formatos PDF, JPG e PNG, limitados ao tamanho máximo de 10MB por arquivo. Qualquer arquivo fora desses parâmetros deve ser rejeitado imediatamente na interface com uma mensagem explicativa clara ao usuário.

---

### RNF11 – Licença e Distribuição

O aplicativo é distribuído sob licença MIT. O código-fonte deve ser mantido no repositório oficial do projeto no GitHub, utilizando Git com uma estratégia clara de branches. A publicação futura do aplicativo está prevista para as lojas oficiais Google Play Store e Apple App Store.
