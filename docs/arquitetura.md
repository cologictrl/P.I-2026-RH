# **Documento de Arquitetura de Software – RHOS (RH Operation System)**

*Projeto Integrado 2026 | P.I-2026-RH-OS | Desenvolvido em Flutter/Dart*

## **1\. Mapeamento de Arquitetura**

### **1.1 Padrão Adotado — Clean Architecture**

O projeto RH-OS adota a **Clean Architecture** com separação explícita em três camadas principais, garantindo a independência total entre regras de negócio, lógica de aplicação e a infraestrutura de nuvem do Firebase. Cada camada se comunica exclusivamente via contratos abstratos (interfaces Dart).

| Camada | Responsabilidade | Tecnologia Principal | Diretório |
| :---- | :---- | :---- | :---- |
| **Presentation** | UI, widgets, navegação, estado local e global | Flutter \+ Riverpod | lib/presentation/ |
| **Domain** | Entidades, casos de uso, interfaces de repositório | Dart puro | lib/domain/ |
| **Data** | Implementações concretas de repositórios e parsers | Firebase SDK | lib/data/ |
| **Core** | Tema, constantes, utilitários, DI (Injeção de Dependência) | get\_it, Riverpod | lib/core/ |

### **1.2 Fluxo de Comunicação entre Camadas**

A comunicação segue estritamente a **Regra da Dependência**: dependências apontam sempre de fora para dentro (Presentation → Domain ← Data). Nenhuma camada interna conhece detalhes da camada externa.

Presentation (Flutter Widgets \+ Riverpod Providers)  
        │  
        ▼  chama via getIt\<ICasoDeUso\>().executar()  
Domain (Casos de Uso \+ Interfaces)  
        │  
        ▼  resolve em tempo de execução via get\_it  
Data (Repositórios Firestore \+ Parsers)  
        │  
        ▼  Firebase SDK (Nativo)  
Infraestrutura (Cloud Firestore / Firebase Auth / Gemini API)

### **1.3 Gerenciamento de Estado — Riverpod**

O estado da aplicação é gerenciado de forma reativa com Riverpod (flutter\_riverpod \+ riverpod\_annotation). Cada funcionalidade possui um Provider dedicado para evitar acoplamento entre telas.

* **AsyncNotifierProvider** — Utilizado para operações assíncronas com o Firestore (carregamento reativo de candidatos, vagas e candidaturas).  
* **StateNotifierProvider** — Controla estados locais de formulários, filtros e fluxos de navegação de passos.

### **1.4 Navegação — go\_router**

A navegação declarativa usa go\_router com **redirect guards** configurados para validar o status de autenticação no Firebase Auth e o perfil do usuário logado. O sistema possui controle de acesso estrito para os **2 atores definidos**: admin e recrutador.

redirect: (context, state) {  
  final uid    \= prefs.getString('usuario\_uid');  
  final perfil \= prefs.getString('usuario\_perfil'); // 'admin' ou 'recrutador'  
    
  if (uid \== null) return '/login';  
    
  // Proteção de rotas administrativas  
  if (state.fullPath \== '/admin' && perfil \!= 'admin') return '/home';  
    
  return null;  
}

## **2\. Princípios de Engenharia**

| Princípio | Aplicação no Projeto | Exemplo Real |
| :---- | :---- | :---- |
| **SRP** | Cada classe tem uma responsabilidade única | CandidatoRepositorioFirestore — lida apenas com queries do Firestore; ExtratorDados — processa regex |
| **OCP** | Interfaces permitem novos comportamentos sem alterar o domínio | ICandidatoRepositorio pode receber uma implementação de Mock para testes sem alterar os Casos de Uso |
| **LSP** | Implementações de teste/produção substituem interfaces perfeitamente | CandidatoRepositorioMock substitui CandidatoRepositorioFirestore mantendo os mesmos contratos |
| **ISP** | Interfaces enxutas e separadas por contexto | IUsuarioRepositorio, ICandidatoRepositorio, IVagaRepositorio em vez de uma interface monolítica de dados |
| **DIP** | Camada domain depende apenas de abstrações | Casos de uso recebem instâncias que estendem IRepositorio via construtor, resolvidas pelo Service Locator |
| **DRY** | Componentização de interface reusável | RhosAppBar, CampoPerfilTile e AvatarIniciais compartilhados no app |
| **Repository Pattern** | Abstração completa do acesso a dados | O domínio interage com IVagaRepositorio, sem saber detalhes de coleções ou documentos do Firestore |
| **Singleton** | Instâncias globais únicas via DI | FirebaseAuthService e instâncias do Firebase configuradas como Singletons no GetIt |
| **Injeção de Dependência** | get\_it como service locator | getIt\<ICandidatoRepositorio\>(), getIt\<ListarCandidatos\>() |
| **Factory Method** | Instanciação de objetos de domínio a partir do NoSQL | Candidato.fromMap(doc.data()) converte o documento do Firestore em Entidade |

## **3\. Integração Firebase**

### **3.1 Autenticação — Firebase Auth**

Gerenciada nativamente pelo **Firebase Authentication** com provedor de Email/Senha. O login gera e valida os tokens de sessão automaticamente através do SDK. O ID do usuário (uid) e o perfil recuperado do Firestore (admin ou \`recrutador\`) são mantidos em cache local para os Guards de rota.

### **3.2 Persistência — Cloud Firestore**

O Firestore funciona como o banco de dados centralizado e único da aplicação. Os dados são estruturados em coleções e documentos:

| Coleção | Entidade | Status | Campos Principais |
| :---- | :---- | :---- | :---- |
| candidatos | Candidato | ✅ Conforme | nome, email, cpf, endereço, resumo, idStr |
| vagas | Vaga | ✅ Conforme | titulo, status, habilidades\_desejadas, idStr |
| candidaturas | Candidatura | ✅ Conforme | candidatoIdStr, vagaIdStr, score, status |
| comentarios | Comentario | ✅ Conforme | candidaturaId, autor, texto |
| notificacoes | Notificacao | ✅ Conforme | titulo, mensagem, lida |
| logs | LogAuditoria | ✅ Conforme | usuarioId, acao, dataHora |

### **3.3 Reatividade — Streams vs Futures**

| Operação | Abordagem | Justificativa |
| :---- | :---- | :---- |
| Listar candidatos | Future (get()) | Lista sob demanda, sem necessidade de tempo real |
| Estado de autenticação | Stream (authStateChanges()) | Reativo a login/logout em tempo real |
| Ranking de candidatos | Future \+ ordenação local | Cálculo de score é síncrono pós-fetch |
| Status de candidatura | Future (update()) | Atualização pontual pelo recrutador |

### **3.4 Regras de Segurança**

rules\_version \= '2';  
service cloud.firestore {  
  match /databases/{database}/documents {  
    match /{document=\*\*} {  
      allow read, write: if request.auth \!= null;  
    }  
  }  
}

### **3.5 Pipeline OCR / IA — Fase 2**

Arquivo selecionado (PDF ou imagem)  
       │  
       ▼  
PdfParser detecta se PDF tem texto selecionável  
       ├── SIM ──▶ ExtratorDados (regex, fase 1\)  
       └── NÃO ──▶ OcrService.extrairTextoDeImagem(bytes)  
                          │  
                          ▼  
               Gemini 2.5 Flash Vision API  
               Prompt estruturado → JSON do currículo  
                          │  
                          ▼  
               Campos preenchidos automaticamente e salvos no Firestore

## **4\. Referência de Diagramas**

| Arquivo | Tipo | Descrição |
| :---- | :---- | :---- |
| UC03-login-firebase-sequencia.puml | Sequência | Login via Firebase Auth |
| UC04-upload-curriculo-sequencia.puml | Sequência | Upload e extração de currículo |
| UC03-login-firebase-atividade.puml | Atividade | Fluxo de atividades do login |
| UC04-upload-curriculo-atividade.puml | Atividade | Fluxo de atividades do upload |
| componentes.puml | Componentes | Relação App vs Firebase |
| classes.puml | Classes | Entidades e repositórios principais |
| diagrama-casos-de-uso.puml | Casos de uso | Atores e casos de uso do sistema |

## **5\. Auditoria — Documentação vs Implementação**

| Requisito | Tipo | Status | Observação |
| :---- | :---- | :---- | :---- |
| Clean Architecture | RNF07 | ✅ Conforme | Camadas core, data, domain e presentation isoladas |
| Firebase Auth | RNF03 | ✅ Conforme | Autenticação nativa com controle baseado em 2 perfis |
| Banco de dados | RNF04 | ✅ Conforme | 100% Cloud Firestore estruturado |
| Riverpod (estado) | RNF08 | ✅ Conforme | Gerenciamento reativo com geração de código (@riverpod) |
| OCR / IA | RF02 | ⏳ Fase 2 | Placeholder OcrService — Gemini 2.5 Flash |
| Score de candidatos | RF04 | ✅ Conforme | Algoritmo local (hab.60% \+ idiomas20% \+ form.20%) |
| Status do candidato | RF05 | ✅ Conforme | Entidade Candidatura com status |
| Controle de acesso | RF08 | ✅ Conforme | Apenas 2 atores apresentados: admin e recrutador |
| Gestão de vagas | RF09 | ✅ Conforme | TelaCriarVaga \+ VagaRepositorioFirestore |
| Deduplicação CPF/email | RN01 | ⏳ Fase 6 | buscarPorCpf \+ buscarPorEmail planejados |
| Relatórios PDF | RF11 | ⏳ Fase futura | Dashboard com fl\_chart em planejamento |

