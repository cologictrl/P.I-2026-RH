# Requisitos Não Funcionais – RHOS (RH Operation System)
## Projeto Integrado 2026 | P.I-2026-RH-OS | Desenvolvido em Flutter/Dart

---

### RNF01 – Plataforma e Compatibilidade

O aplicativo é desenvolvido em Flutter com linguagem Dart, sendo compatível com dispositivos Android e iOS. O ambiente mínimo exigido para execução é Flutter SDK 3.0 ou superior. Para dispositivos Android, a versão mínima suportada é Android 8.0 (API 26), e para iOS, a versão mínima é iOS 13.

---

### RNF02 – Desempenho na Extração de Currículos

A leitura e extração automática de informações de um currículo via inteligência artificial deve ser concluída em no máximo 15 segundos para arquivos de até 5MB. Para arquivos maiores ou com múltiplas páginas, o sistema deve exibir uma barra de progresso informando ao usuário que o processamento está em andamento.

---

### RNF03 – Segurança e Autenticação

O aplicativo deve utilizar autenticação via JWT (JSON Web Token) com controle de permissões baseado em perfis (RBAC), integrado a uma API backend. As senhas dos usuários devem ser armazenadas com algoritmo de hash seguro e nunca em texto puro. O token de sessão deve expirar após 8 horas de inatividade, sendo gerenciado com segurança pelo Flutter Secure Storage.

---

### RNF04 – Armazenamento de Dados

Os dados do aplicativo devem ser persistidos localmente utilizando SQLite via pacote sqflite do Flutter para armazenamento offline, e sincronizados com uma API REST quando houver conexão com a internet. Dados sensíveis, como tokens de sessão, devem ser armazenados com Flutter Secure Storage.

---

### RNF05 – Usabilidade

A interface do sistema deve ser intuitiva o suficiente para que um recrutador sem treinamento técnico consiga realizar as operações básicas, como cadastrar um candidato, importar um currículo e consultar o histórico, sem necessidade de suporte. O tempo estimado de aprendizado para uso básico do sistema não deve ultrapassar uma hora.

---

### RNF06 – Disponibilidade e Modo Offline

O aplicativo deve funcionar em modo offline para as funcionalidades básicas de consulta e visualização de candidatos já cadastrados, utilizando o banco de dados local SQLite. A conexão com a internet é necessária para as funcionalidades que utilizam inteligência artificial, como extração e análise de currículos, e para sincronização dos dados com o servidor.

---

### RNF07 – Manutenibilidade

O código-fonte do projeto deve seguir a arquitetura limpa (Clean Architecture) ou o padrão MVC adaptado para Flutter, separando as responsabilidades entre camadas de apresentação, domínio e dados. O uso de comentários no código é obrigatório em funções e widgets principais, seguindo os padrões de documentação do Dart com dartdoc.

---

### RNF08 – Escalabilidade

A arquitetura do aplicativo deve permitir que novas funcionalidades sejam adicionadas sem necessidade de reestruturação completa do projeto. O gerenciamento de estado deve ser feito com Provider ou Riverpod, garantindo que novos módulos possam ser incorporados de forma independente sem quebrar o que já está funcionando.

---

### RNF09 – Logs e Auditoria

O sistema deve registrar automaticamente em log todas as ações relevantes realizadas pelos usuários, como login, alteração de status de candidatos, encerramento de processos e geração de relatórios. Esses logs devem ser armazenados no banco de dados e acessíveis somente pelo administrador.

---

### RNF10 – Tamanho e Formato de Arquivos Aceitos

O sistema deve aceitar currículos nos formatos PDF, JPG e PNG. O tamanho máximo por arquivo é de 10MB. Arquivos fora desses formatos ou acima do tamanho permitido devem ser rejeitados com uma mensagem clara informando o motivo e os formatos aceitos.

---

### RNF11 – Licença e Distribuição

O aplicativo é distribuído sob licença MIT, sendo livre para uso pessoal e comercial. O código-fonte deve ser mantido no repositório oficial do projeto no GitHub, com versionamento utilizando Git e organização de branches seguindo o padrão definido pela equipe. A publicação nas lojas (Google Play e App Store) é prevista para fases futuras do projeto.
